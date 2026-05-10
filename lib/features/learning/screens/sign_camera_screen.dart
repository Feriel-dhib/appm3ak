import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image/image.dart' as img;
import 'package:appm3ak/core/config/app_config.dart';
import 'package:appm3ak/core/errors/ai_module_exception.dart';
import 'package:appm3ak/data/api/ai_module_api_client.dart';
import 'package:appm3ak/data/repositories/ai_module_repository.dart';
import 'package:appm3ak/features/learning/models/sign_explain_response.dart';

class SignCameraScreen extends StatefulWidget {
  const SignCameraScreen({super.key});

  @override
  State<SignCameraScreen> createState() => _SignCameraScreenState();
}

class _SignCameraScreenState extends State<SignCameraScreen> {
  late final String _signBackendBaseUrl =
      (AppConfig.aiModuleSecondaryBaseUrl != null &&
          AppConfig.aiModuleSecondaryBaseUrl!.trim().isNotEmpty)
      ? AppConfig.aiModuleSecondaryBaseUrl!.trim()
      : AppConfig.aiModuleBaseUrl;
  late final AiModuleRepository _aiRepository = AiModuleRepository(
    apiClient: AiModuleApiClient(baseUrl: _signBackendBaseUrl),
  );
  final FlutterTts _tts = FlutterTts();
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isAnalyzing = false;
  bool _isAutoAnalyzeEnabled = false;
  bool _isMuted = false;
  String? _error;
  SignExplainResponse? _lastResult;
  final List<String> _recognizedWords = [];
  DateTime? _lastAnalyzedAt;
  List<CameraDescription> _cameras = const [];
  int _selectedCameraIndex = 0;
  Timer? _autoAnalyzeTimer;
  bool _isImageStreamRunning = false;
  bool _isLiveFrameInFlight = false;
  CameraImage? _latestCameraImage;
  DateTime? _lastLiveSentAt;
  DateTime? _lastUiRefreshAt;

  /// Intervalle minimum entre deux envois live (adapté à la latence serveur).
  Duration _adaptiveAnalyzeInterval = const Duration(milliseconds: 1000);
  double _latencyEmaMs = 700;

  /// Anti-oscillation : même mot normalisé sur N analyses avant TTS / historique stable.
  static const int _confirmFramesForTts = 3;
  static const double _minConfidenceForStabilize = 0.38;
  static const int _noSignFramesToBreak = 2;

  String? _stabilizationCandidateNorm;
  int _stabilizationStreak = 0;
  int _noSignStreak = 0;
  String? _lastConfirmedSpokenWord;
  String? _lastStabilizedDisplayWord;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initCamera();
    _checkBackendHealth();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.0);
    } catch (_) {
      // TTS remains optional; camera and analysis must continue.
    }
  }

  Future<void> _checkBackendHealth() async {
    try {
      final ok = await _aiRepository.isHealthy();
      if (!ok) {
        if (!mounted) return;
        setState(() {
          _error = 'Backend IA indisponible ($_signBackendBaseUrl).';
        });
        return;
      }
      final models = await _aiRepository.listModels();
      final hasSignExplain = models.models.any(
        (m) => m.name.trim().toLowerCase() == 'sign_explain',
      );
      if (!mounted || hasSignExplain) return;
      setState(() {
        _error = 'Modele sign_explain absent sur $_signBackendBaseUrl.';
      });
    } on AiModuleException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Backend IA introuvable ($_signBackendBaseUrl). Verifiez le serveur Flask.';
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _error = 'Aucune camera disponible.';
        });
        return;
      }

      _cameras = cameras;
      _selectedCameraIndex = 0;
      await _startCamera(_cameras[_selectedCameraIndex]);
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _error = 'Impossible d ouvrir la camera: $e';
      });
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    await _controller?.dispose();
    final controller = CameraController(
      camera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isInitializing = false;
        _error = null;
      });
      await _configureLiveStream();
      _startAutoAnalyze();
    } catch (e) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _error = 'Erreur camera: $e';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isAnalyzing) return;
    setState(() => _isInitializing = true);
    _autoAnalyzeTimer?.cancel();
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _startCamera(_cameras[_selectedCameraIndex]);
  }

  void _startAutoAnalyze() {
    _autoAnalyzeTimer?.cancel();
    if (!_isAutoAnalyzeEnabled) return;
    // Boucle légère : le flux image + `_adaptiveAnalyzeInterval` limitent les vrais envois.
    _autoAnalyzeTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!_isAnalyzing && mounted) {
        _analyzeCurrentFrame();
      }
    });
  }

  String? _normalizeWord(String? w) {
    if (w == null) return null;
    final t = w.trim();
    if (t.isEmpty) return null;
    return t.toUpperCase();
  }

  void _recordRoundTrip(Duration dt) {
    final ms = dt.inMilliseconds.clamp(40, 60000).toDouble();
    _latencyEmaMs = _latencyEmaMs * 0.62 + ms * 0.38;
    _adaptiveAnalyzeInterval = _intervalForLatencyEma(_latencyEmaMs);
  }

  Duration _intervalForLatencyEma(double emaMs) {
    if (emaMs < 420) return const Duration(milliseconds: 700);
    if (emaMs < 850) return const Duration(milliseconds: 1000);
    return const Duration(milliseconds: 1550);
  }

  String _livePaceLabel() {
    if (_latencyEmaMs < 420) return 'Live: rapide';
    if (_latencyEmaMs < 850) return 'Live: normal';
    return 'Live: lent (reseau)';
  }

  /// Met à jour la stabilisation et parle seulement après [ _confirmFramesForTts ] hits consécutifs.
  void _applyStabilizationAndMaybeSpeak(SignExplainResponse result) {
    final norm = _normalizeWord(result.detectedWord);
    final okConf = result.confidence >= _minConfidenceForStabilize;

    if (norm == null || !okConf) {
      _noSignStreak++;
      if (_noSignStreak >= _noSignFramesToBreak) {
        _stabilizationStreak = 0;
        _stabilizationCandidateNorm = null;
        _lastConfirmedSpokenWord = null;
        _lastStabilizedDisplayWord = null;
      }
      return;
    }

    _noSignStreak = 0;

    if (_stabilizationCandidateNorm == norm) {
      _stabilizationStreak++;
    } else {
      _stabilizationCandidateNorm = norm;
      _stabilizationStreak = 1;
    }

    final displayWord = result.detectedWord!.trim();

    if (_stabilizationStreak >= _confirmFramesForTts) {
      _lastStabilizedDisplayWord = displayWord;
      final alreadySpoken = _lastConfirmedSpokenWord != null &&
          _normalizeWord(_lastConfirmedSpokenWord) == norm;
      if (!alreadySpoken) {
        _lastConfirmedSpokenWord = displayWord;
        _recognizedWords.add(displayWord);
        if (_recognizedWords.length > 8) {
          _recognizedWords.removeAt(0);
        }
        _speakWord(displayWord);
      }
    }
  }

  /// Libellé « signe » pour l’overlay (brut + progression de stabilisation).
  String _overlaySignLabel() {
    final r = _lastResult;
    if (r == null) return 'Aucun';
    final raw = r.detectedWord?.trim();
    if (raw == null || raw.isEmpty) {
      final t = _lastAnalyzedAt;
      if (t != null &&
          DateTime.now().difference(t) < const Duration(milliseconds: 600)) {
        return _lastStabilizedDisplayWord ?? 'Aucun';
      }
      return 'Aucun';
    }
    final okConf = r.confidence >= _minConfidenceForStabilize;
    if (!okConf) {
      return '$raw (faible)';
    }
    final norm = _normalizeWord(raw);
    if (norm != null &&
        _stabilizationCandidateNorm == norm &&
        _stabilizationStreak >= _confirmFramesForTts) {
      return _lastStabilizedDisplayWord ?? raw;
    }
    if (norm != null &&
        _stabilizationCandidateNorm == norm &&
        _stabilizationStreak > 0 &&
        _stabilizationStreak < _confirmFramesForTts) {
      return '$raw ($_stabilizationStreak/$_confirmFramesForTts)';
    }
    return raw;
  }

  Future<void> _analyzeCurrentFrame() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isAnalyzing) {
      return;
    }

    // Mode live: analyse directe des frames du flux caméra.
    if (_isImageStreamRunning && _latestCameraImage != null) {
      await _analyzeCameraImage(_latestCameraImage!);
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final XFile snapshot = await controller.takePicture();
      final bytes = await snapshot.readAsBytes();
      final sw = Stopwatch()..start();
      final result = await _predictFromBytes(bytes);
      sw.stop();
      _recordRoundTrip(sw.elapsed);
      try {
        final f = File(snapshot.path);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
      if (!mounted) return;
      final stabS0 = _stabilizationStreak;
      final stabC0 = _stabilizationCandidateNorm;
      _applyStabilizationAndMaybeSpeak(result);
      final stabChanged =
          stabS0 != _stabilizationStreak || stabC0 != _stabilizationCandidateNorm;

      final now = DateTime.now();
      final prev = _lastResult;
      final changed = prev == null ||
          prev.detectedWord != result.detectedWord ||
          prev.explanation != result.explanation ||
          (prev.confidence - result.confidence).abs() > 0.07;
      final shouldRefreshUi = _lastUiRefreshAt == null ||
          now.difference(_lastUiRefreshAt!) > const Duration(milliseconds: 400) ||
          changed ||
          stabChanged;
      if (shouldRefreshUi) {
        _lastUiRefreshAt = now;
        setState(() {
          _lastResult = result;
          _lastAnalyzedAt = DateTime.now();
        });
      }
    } catch (e) {
      if (!mounted) return;
      String msg;
      if (e is AiModuleException) {
        msg = e.message;
      } else if (e is DioException) {
        final status = e.response?.statusCode;
        final data = e.response?.data;
        final detail = (data is Map && data['detail'] != null)
            ? data['detail'].toString()
            : data?.toString();

        if (status != null) {
          msg = 'Analyse IA impossible (HTTP $status): ${detail ?? e.message}';
        } else {
          msg = 'Analyse IA impossible: ${e.message}';
        }
      } else {
        msg = 'Analyse IA impossible: $e';
      }
      setState(() {
        _error = msg;
      });
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _analyzeCameraImage(CameraImage frame) async {
    if (_isLiveFrameInFlight || _isAnalyzing) return;
    final now = DateTime.now();
    if (_lastLiveSentAt != null &&
        now.difference(_lastLiveSentAt!) < _adaptiveAnalyzeInterval) {
      return;
    }
    _isLiveFrameInFlight = true;
    _lastLiveSentAt = now;
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });
    SignExplainResponse? result;
    var refreshHeavy = false;
    try {
      final jpegBytes = _cameraImageToJpeg(frame);
      final sw = Stopwatch()..start();
      result = await _predictFromBytes(jpegBytes);
      sw.stop();
      _recordRoundTrip(sw.elapsed);
      if (!mounted) return;

      final stabS0 = _stabilizationStreak;
      final stabC0 = _stabilizationCandidateNorm;
      _applyStabilizationAndMaybeSpeak(result);
      final stabChanged =
          stabS0 != _stabilizationStreak || stabC0 != _stabilizationCandidateNorm;

      final tick = DateTime.now();
      final prev = _lastResult;
      final changed = prev == null ||
          prev.detectedWord != result.detectedWord ||
          prev.explanation != result.explanation ||
          (prev.confidence - result.confidence).abs() > 0.07;
      refreshHeavy = _lastUiRefreshAt == null ||
          tick.difference(_lastUiRefreshAt!) > const Duration(milliseconds: 400) ||
          changed ||
          stabChanged;
      if (refreshHeavy) {
        _lastUiRefreshAt = tick;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyAiError(e);
      });
    } finally {
      _isLiveFrameInFlight = false;
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          if (result != null && refreshHeavy) {
            _lastResult = result;
            _lastAnalyzedAt = DateTime.now();
            _error = null;
          }
        });
      }
    }
  }

  Future<SignExplainResponse> _predictFromBytes(Uint8List bytes) async {
    final json = await _aiRepository.predictImageBase64(
      'sign_explain',
      imageBase64: base64Encode(bytes),
    );
    return _mapSignExplainResponse(json);
  }

  SignExplainResponse _mapSignExplainResponse(Map<String, dynamic> json) {
    final payload = (json['result'] is Map<String, dynamic>)
        ? json['result'] as Map<String, dynamic>
        : json;
    final word = payload['detected_word']?.toString() ??
        payload['word']?.toString() ??
        payload['sign']?.toString() ??
        payload['label']?.toString();
    final explanation = payload['explanation']?.toString() ??
        payload['message']?.toString() ??
        '';
    final raisedFingers =
        (payload['raised_fingers'] as List<dynamic>? ??
                payload['fingers'] as List<dynamic>? ??
                const [])
            .map((e) => e.toString())
            .toList();
    final raisedCount =
        int.tryParse(payload['raised_fingers_count']?.toString() ?? '') ??
            raisedFingers.length;
    final confidence =
        (double.tryParse(payload['confidence']?.toString() ?? '') ?? 0.0)
            .clamp(0.0, 1.0);
    final landmarksJson = (payload['landmarks'] as List<dynamic>? ?? const []);
    final landmarks = landmarksJson
        .whereType<Map<String, dynamic>>()
        .map(SignLandmark.fromJson)
        .toList();

    return SignExplainResponse(
      detectedWord: word,
      explanation: explanation,
      raisedFingers: raisedFingers,
      raisedFingersCount: raisedCount,
      confidence: confidence,
      landmarks: landmarks,
    );
  }

  @override
  void dispose() {
    _autoAnalyzeTimer?.cancel();
    _stopImageStream();
    _tts.stop();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _speakWord(String word) async {
    if (_isMuted || word.trim().isEmpty) return;
    try {
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 100)); // Délai pour éviter les conflits
      await _tts.speak(word);
    } catch (e) {
      // Ignorer les erreurs TTS pour garder l'UX stable
      debugPrint('TTS Error: $e');
    }
  }

  void _toggleAutoAnalyze() {
    setState(() {
      _isAutoAnalyzeEnabled = !_isAutoAnalyzeEnabled;
    });
    _configureLiveStream();
    _startAutoAnalyze();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    if (_isMuted) {
      _tts.stop();
    }
  }

  void _clearSession() {
    setState(() {
      _recognizedWords.clear();
      _lastResult = null;
      _error = null;
      _stabilizationCandidateNorm = null;
      _stabilizationStreak = 0;
      _noSignStreak = 0;
      _lastConfirmedSpokenWord = null;
      _lastStabilizedDisplayWord = null;
      _lastUiRefreshAt = null;
    });
  }

  Future<void> _configureLiveStream() async {
    if (_isAutoAnalyzeEnabled) {
      await _startImageStream();
    } else {
      await _stopImageStream();
    }
  }

  Future<void> _startImageStream() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isImageStreamRunning) {
      return;
    }
    try {
      await controller.startImageStream((image) {
        _latestCameraImage = image;
      });
      _isImageStreamRunning = true;
    } catch (_) {
      _isImageStreamRunning = false;
    }
  }

  Future<void> _stopImageStream() async {
    final controller = _controller;
    if (controller == null || !_isImageStreamRunning) return;
    try {
      await controller.stopImageStream();
    } catch (_) {}
    _isImageStreamRunning = false;
    _latestCameraImage = null;
  }

  Uint8List _cameraImageToJpeg(CameraImage image) {
    if (image.format.group == ImageFormatGroup.bgra8888) {
      return _bgraToJpeg(image);
    }
    return _yuv420ToJpeg(image);
  }

  Uint8List _bgraToJpeg(CameraImage image) {
    final plane = image.planes.first;
    final bytes = plane.bytes;
    final width = image.width;
    final height = image.height;
    final bytesPerRow = plane.bytesPerRow;
    final converted = Uint8List(width * height * 3);
    var out = 0;
    for (var y = 0; y < height; y++) {
      final rowStart = y * bytesPerRow;
      for (var x = 0; x < width; x++) {
        final i = rowStart + x * 4;
        final b = bytes[i];
        final g = bytes[i + 1];
        final r = bytes[i + 2];
        converted[out++] = r;
        converted[out++] = g;
        converted[out++] = b;
      }
    }
    final rgb = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: converted.buffer,
      numChannels: 3,
    );
    final optimized = _optimizeForNetwork(rgb);
    return Uint8List.fromList(img.encodeJpg(optimized, quality: 55));
  }

  Uint8List _yuv420ToJpeg(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final out = img.Image(width: width, height: height);
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;
    for (var y = 0; y < height; y++) {
      final yRow = y * yPlane.bytesPerRow;
      final uvRow = (y >> 1) * uvRowStride;
      for (var x = 0; x < width; x++) {
        final uvIndex = uvRow + (x >> 1) * uvPixelStride;
        final yp = yPlane.bytes[yRow + x];
        final up = uPlane.bytes[uvIndex];
        final vp = vPlane.bytes[uvIndex];
        final r = (yp + 1.402 * (vp - 128)).round().clamp(0, 255);
        final g =
            (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128)).round().clamp(
                  0,
                  255,
                );
        final b = (yp + 1.772 * (up - 128)).round().clamp(0, 255);
        out.setPixelRgb(x, y, r, g, b);
      }
    }
    final optimized = _optimizeForNetwork(out);
    return Uint8List.fromList(img.encodeJpg(optimized, quality: 55));
  }

  img.Image _optimizeForNetwork(img.Image src) {
    const maxSide = 640;
    final longest = src.width > src.height ? src.width : src.height;
    if (longest <= maxSide) return src;
    if (src.width >= src.height) {
      return img.copyResize(src, width: maxSide);
    }
    return img.copyResize(src, height: maxSide);
  }

  String _friendlyAiError(Object e) {
    if (e is AiModuleException) return e.message;
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status != null) return 'Analyse IA impossible (HTTP $status).';
      return 'Analyse IA impossible: ${e.message}';
    }
    return 'Analyse IA impossible: $e';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        title: const Text(
          'Camera IA - Traducteur complet',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child: _buildCameraArea(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildStatusStrip(),
            const SizedBox(height: 10),
            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            if (_lastResult != null) _buildResultCard(_lastResult!),
            if (_recognizedWords.isNotEmpty) _buildHistoryCard(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isInitializing ? null : _switchCamera,
                    icon: const Icon(Icons.cameraswitch),
                    label: const Text('Changer camera'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF4CAF50)),
                      foregroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isInitializing || _isAnalyzing)
                        ? null
                        : _analyzeCurrentFrame,
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.psychology),
                    label: Text(_isAnalyzing ? 'Analyse...' : 'Analyser IA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isInitializing ? null : _toggleAutoAnalyze,
                    icon: Icon(
                      _isAutoAnalyzeEnabled
                          ? Icons.pause_circle
                          : Icons.play_circle,
                    ),
                    label: Text(_isAutoAnalyzeEnabled ? 'Pause auto' : 'Auto ON'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleMute,
                    icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
                    label: Text(_isMuted ? 'Muet' : 'Voix'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearSession,
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: const Text('Nettoyer'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraArea() {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: Text(
          'Camera indisponible',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),
        if (_lastResult != null && _lastResult!.landmarks.isNotEmpty)
          CustomPaint(
            painter: _HandLandmarksPainter(
              landmarks: _lastResult!.landmarks,
            ),
          ),
        if (_isAnalyzing)
          const Align(
            alignment: Alignment.center,
            child: CircularProgressIndicator(color: Colors.white),
          ),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isAutoAnalyzeEnabled
                  ? 'Live: ${_livePaceLabel()} · Voix après $_confirmFramesForTts confirmations'
                  : 'Analyse auto en pause - utilisez "Analyser IA"',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
        if (_lastResult != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Signe: ${_overlaySignLabel()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _lastResult!.explanation,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultCard(SignExplainResponse result) {
    final detected = result.detectedWord ?? 'Aucun signe';
    final fingers = result.raisedFingers.isEmpty
        ? 'Aucun doigt detecte'
        : result.raisedFingers.join(', ');
    final confidencePct = (result.confidence * 100).clamp(0, 100).toStringAsFixed(0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.record_voice_over, color: Color(0xFF2E7D32), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Signe detecte: $detected',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.explanation,
            style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 8),
          Text(
            'Doigts: ${result.raisedFingersCount} ($fingers) · Confiance: $confidencePct%',
            style: const TextStyle(
              color: Color(0xFF2E7D32),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1976D2).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mots reconnus',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recognizedWords.reversed.map((word) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  word,
                  style: const TextStyle(
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStrip() {
    final last = _lastAnalyzedAt;
    final lastText = last == null
        ? '--'
        : '${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}:${last.second.toString().padLeft(2, '0')}';
    final statusColor = _error == null ? const Color(0xFF2E7D32) : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.22)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _StatusChip(
            label: _error == null ? 'Backend: connecte' : 'Backend: erreur',
            color: statusColor,
            icon: _error == null ? Icons.cloud_done : Icons.cloud_off,
          ),
          _StatusChip(
            label: _isAutoAnalyzeEnabled ? 'Auto: ON' : 'Auto: OFF',
            color: const Color(0xFF1565C0),
            icon: _isAutoAnalyzeEnabled ? Icons.bolt : Icons.bolt_outlined,
          ),
          _StatusChip(
            label: _isMuted ? 'Voix: OFF' : 'Voix: ON',
            color: const Color(0xFF6A1B9A),
            icon: _isMuted ? Icons.volume_off : Icons.volume_up,
          ),
          _StatusChip(
            label: 'Derniere analyse: $lastText',
            color: const Color(0xFF00897B),
            icon: Icons.schedule,
          ),
          _StatusChip(
            label: '${_livePaceLabel()} (~${_latencyEmaMs.round()} ms)',
            color: const Color(0xFF3949AB),
            icon: Icons.speed,
          ),
          _StatusChip(
            label: 'Confirmation voix: $_confirmFramesForTts frames',
            color: const Color(0xFF6D4C41),
            icon: Icons.hearing_outlined,
          ),
          _StatusChip(
            label: 'Mots: ${_recognizedWords.length}',
            color: const Color(0xFFEF6C00),
            icon: Icons.history,
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HandLandmarksPainter extends CustomPainter {
  _HandLandmarksPainter({required this.landmarks});

  final List<SignLandmark> landmarks;

  static const List<List<int>> _connections = [
    [0, 1], [1, 2], [2, 3], [3, 4],
    [0, 5], [5, 6], [6, 7], [7, 8],
    [5, 9], [9, 10], [10, 11], [11, 12],
    [9, 13], [13, 14], [14, 15], [15, 16],
    [13, 17], [17, 18], [18, 19], [19, 20],
    [0, 17],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final pointPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = const Color(0xAA00E676)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final c in _connections) {
      if (c[0] < landmarks.length && c[1] < landmarks.length) {
        final p1 = Offset(landmarks[c[0]].x * size.width, landmarks[c[0]].y * size.height);
        final p2 = Offset(landmarks[c[1]].x * size.width, landmarks[c[1]].y * size.height);
        canvas.drawLine(p1, p2, linePaint);
      }
    }

    for (final lm in landmarks) {
      final point = Offset(lm.x * size.width, lm.y * size.height);
      canvas.drawCircle(point, 3.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HandLandmarksPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks;
  }
}

