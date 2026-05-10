import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:record/record.dart';

import 'voice_local_stress_analyzer.dart';
import 'voice_stress_api_client.dart';
import '../models/voice_stress_api_result.dart';

/// Enregistrement WAV court + envoi au backend Python (librosa / MFCC).
class VoiceStressRecorderService {
  VoiceStressRecorderService({
    VoiceStressApiClient? apiClient,
    AudioRecorder? recorder,
  })  : _api = apiClient ?? VoiceStressApiClient(),
        _recorder = recorder ?? AudioRecorder();

  final VoiceStressApiClient _api;
  final AudioRecorder _recorder;

  /// Durée conseillée pour des features stables (secondes).
  static const int defaultRecordSeconds = 5;

  Future<bool> ensureMicPermission() async {
    if (kIsWeb) return false;
    var s = await Permission.microphone.status;
    if (s.isGranted) return true;
    s = await Permission.microphone.request();
    return s.isGranted;
  }

  Future<bool> canRecord() async {
    if (kIsWeb) return false;
    return _recorder.hasPermission();
  }

  /// Enregistre [seconds] s en WAV 16 kHz mono, envoie à l’API Python si disponible,
  /// sinon analyse locale (RMS / ZCR) pour éviter de bloquer sans serveur.
  Future<VoiceStressApiResult> recordAndAnalyze({
    int seconds = defaultRecordSeconds,
  }) async {
    if (kIsWeb) {
      throw StateError('Enregistrement stress vocal non supporté sur le web');
    }
    if (!await ensureMicPermission()) {
      throw StateError('permission_microphone_denied');
    }
    if (!await _recorder.hasPermission()) {
      throw StateError('permission_microphone_denied');
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/ma3ak_stress_${DateTime.now().millisecondsSinceEpoch}.wav';
    String? recordedPath;

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      await Future<void>.delayed(Duration(seconds: seconds));
      recordedPath = await _recorder.stop() ?? path;
      if (!File(recordedPath).existsSync()) {
        throw StateError('fichier_audio_manquant');
      }
      try {
        return await _api.analyzeWavFile(recordedPath);
      } on DioException catch (_) {
        return VoiceLocalStressAnalyzer.analyzeWavFile(recordedPath);
      }
    } finally {
      try {
        await _recorder.stop();
      } catch (_) {}
      final f = File(path);
      if (f.existsSync()) await f.delete();
      if (recordedPath != null && recordedPath != path) {
        final g = File(recordedPath);
        if (g.existsSync()) await g.delete();
      }
    }
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }

  String get helperFr =>
      'Enregistrement ~${defaultRecordSeconds}s → analyse Python (MFCC) si le serveur '
      'tourne sur le port 8000 ; sinon analyse locale (énergie / ZCR).';
}
