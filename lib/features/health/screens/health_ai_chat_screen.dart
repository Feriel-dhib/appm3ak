import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/ai/adapt_models.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/ai_module_providers.dart';
import '../../../providers/health_providers.dart';
import '../services/health_ai_service.dart';
import '../services/health_voice_lang.dart';
import '../services/health_voice_service.dart';

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final fg = isUser
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: SelectableText(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fg,
                height: 1.35,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HealthAiModuleBanner extends StatelessWidget {
  const _HealthAiModuleBanner({required this.health, required this.mode});

  final AsyncValue<bool> health;
  final AsyncValue<AiInteractionMode>? mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final online = health.valueOrNull == true;
    final modeValue = mode?.valueOrNull;
    final modeText = switch (modeValue) {
      AiInteractionMode.voiceMode => 'vocal',
      AiInteractionMode.textMode => 'texte',
      AiInteractionMode.gestureMode => 'gestes',
      null => 'texte',
    };
    final text = health.when(
      data: (ok) => ok
          ? 'Module AI connecté: adaptation $modeText active.'
          : 'Module AI hors ligne: le chat et la voix locale restent disponibles.',
      loading: () => 'Vérification du module AI...',
      error: (error, stackTrace) =>
          'Module AI hors ligne: le chat et la voix locale restent disponibles.',
    );

    return Material(
      color: online
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
          : theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              online ? Icons.psychology_alt_outlined : Icons.cloud_off_outlined,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chatbot santé avec réponses contextuelles et lecture vocale FR/EN.
class HealthAiChatScreen extends ConsumerStatefulWidget {
  const HealthAiChatScreen({
    super.key,
    required this.strings,
    this.initialUserMessage,
    this.userProfile,
  });

  final AppStrings strings;
  final String? initialUserMessage;
  final UserModel? userProfile;

  @override
  ConsumerState<HealthAiChatScreen> createState() => _HealthAiChatScreenState();
}

class _HealthAiChatScreenState extends ConsumerState<HealthAiChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _voice = HealthVoiceService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final _ai = const HealthAiService();

  final List<({bool user, String text})> _messages = [];
  late HealthVoiceLang _voiceLang;
  bool _autoSpeak = true;
  bool _listening = false;
  bool _speechReady = false;
  bool _replyBusy = false;

  /// Dernière transcription (partielle ou finale) pour la session micro en cours.
  String _lastSpeechText = '';

  /// Évite un double envoi si `finalResult` et arrêt manuel arrivent tous les deux.
  bool _speechSessionSent = false;

  /// Évite deux finalisations simultanées (ex. `onStatus` + bouton Stop).
  bool _speechFinalizeInProgress = false;
  static const _disclaimerBannerFr = HealthAiService.disclaimerFr;
  static const _disclaimerBannerEn = HealthAiService.disclaimerEn;

  @override
  void initState() {
    super.initState();
    final u = widget.userProfile;
    final lang = u?.langue.toLowerCase() ?? '';
    _voiceLang = lang == 'en' ? HealthVoiceLang.en : HealthVoiceLang.fr;
    _bootstrapSpeech();
    final seed = widget.initialUserMessage;
    if (seed != null && seed.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_send(seed)),
      );
    }
  }

  Future<bool> _ensureMicrophonePermission() async {
    if (kIsWeb) return true;
    var status = await Permission.microphone.status;
    if (status.isGranted) return true;
    status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _bootstrapSpeech() async {
    if (!kIsWeb) {
      final allowed = await _ensureMicrophonePermission();
      if (!allowed) {
        _speechReady = false;
        if (mounted) setState(() {});
        return;
      }
    }
    try {
      _speechReady = await _speech.initialize(
        onStatus: (s) {
          if (s != 'done' && s != stt.SpeechToText.notListeningStatus) {
            return;
          }
          if (!mounted || !_listening) return;
          if (!_speechSessionSent && _lastSpeechText.trim().isNotEmpty) {
            unawaited(_finishSpeechFromMic(userPressedStop: false));
          } else {
            setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
    } catch (_) {
      _speechReady = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _speech.stop();
    _voice.stop();
    super.dispose();
  }

  String? _profileHintForRemote() {
    final u = widget.userProfile;
    final h = ref.read(healthDashboardProvider);
    final parts = <String>[];
    final th = u?.typeHandicap?.trim();
    if (th != null && th.isNotEmpty) {
      parts.add('Situation / handicap (profil): $th');
    }
    final bs = u?.besoinSpecifique?.trim();
    if (bs != null && bs.isNotEmpty) {
      parts.add('Besoins spécifiques (profil): $bs');
    }
    if (h.medications.isNotEmpty) {
      parts.add(
        'L’utilisateur a des rappels médicaments dans l’app (${h.medications.length}).',
      );
    }
    if (h.latestGlucose != null) {
      parts.add(
        'Une glycémie a été enregistrée récemment dans l’app (ne pas interpréter la valeur ici).',
      );
    }
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  HealthUserContext _profileContext() {
    final u = widget.userProfile;
    final health = ref.read(healthDashboardProvider);
    return HealthUserContext(
      typeHandicap: u?.typeHandicap,
      besoinSpecifique: u?.besoinSpecifique,
      hasRecentGlucoseLog: health.latestGlucose != null,
      fastingForAnalysis: health.fastingForAnalysis,
    );
  }

  Future<void> _send([String? raw]) async {
    final s = widget.strings;
    final text = (raw ?? _controller.text).trim();
    if (text.isEmpty || _replyBusy) return;
    _controller.clear();
    setState(() {
      _replyBusy = true;
      _messages.add((user: true, text: text));
    });
    _scrollBottom();

    final langCode = _voiceLang == HealthVoiceLang.fr ? 'fr' : 'en';
    String out;
    try {
      final remote = await ref
          .read(healthChatRepositoryProvider)
          .sendMessage(
            message: text,
            lang: langCode,
            profileHint: _profileHintForRemote(),
          );
      if (remote != null) {
        out = remote;
      } else {
        final reply = _ai.chatReply(
          text,
          voiceLang: _voiceLang,
          profile: _profileContext(),
        );
        out = _voiceLang == HealthVoiceLang.fr ? reply.fr : reply.en;
      }
    } catch (_) {
      final reply = _ai.chatReply(
        text,
        voiceLang: _voiceLang,
        profile: _profileContext(),
      );
      out = _voiceLang == HealthVoiceLang.fr ? reply.fr : reply.en;
    }

    if (!mounted) return;
    setState(() {
      _messages.add((user: false, text: out));
      _replyBusy = false;
    });
    _scrollBottom();

    if (_autoSpeak) {
      final ok = await _voice.speak(out, _voiceLang);
      unawaited(_speakWithAiModuleIfAvailable(out));
      if (!ok && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.healthVoiceUnavailable)));
      }
    }
  }

  Future<void> _speakWithAiModuleIfAvailable(String text) async {
    final user = widget.userProfile;
    if (user == null) return;
    final mode = ref.read(aiInteractionModeProvider(user)).valueOrNull;
    final online = ref.read(aiModuleHealthProvider).valueOrNull == true;
    if (!online || mode != AiInteractionMode.voiceMode) return;
    try {
      await ref.read(aiModuleRepositoryProvider).speakText(text);
    } catch (_) {
      // Le TTS Flask parle côté serveur; l'app conserve le TTS local comme UX principale.
    }
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<String> _resolveSpeechLocaleId() async {
    final wantFr = _voiceLang == HealthVoiceLang.fr;
    try {
      final locales = await _speech.locales();
      final ids = locales.map((e) => e.localeId).toList();
      if (wantFr) {
        for (final id in ids) {
          final low = id.toLowerCase();
          if (low.startsWith('fr') || low.contains('_fr')) return id;
        }
      } else {
        for (final id in ids) {
          final low = id.toLowerCase();
          if (low.startsWith('en')) return id;
        }
      }
    } catch (_) {}
    return wantFr ? 'fr_FR' : 'en_US';
  }

  Future<void> _finishSpeechFromMic({required bool userPressedStop}) async {
    if (_speechFinalizeInProgress) return;
    _speechFinalizeInProgress = true;
    try {
      await _voice.stop();
      await _speech.stop();
      if (!mounted) return;
      setState(() => _listening = false);

      if (_speechSessionSent) {
        _lastSpeechText = '';
        _speechSessionSent = false;
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      final pending = _lastSpeechText.trim();
      if (pending.isNotEmpty) {
        _speechSessionSent = true;
        _lastSpeechText = '';
        await _send(pending);
      } else if (userPressedStop && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.strings.healthChatNothingHeard)),
        );
      }
      _speechSessionSent = false;
      _lastSpeechText = '';
    } finally {
      _speechFinalizeInProgress = false;
    }
  }

  Future<void> _toggleMic() async {
    if (_replyBusy) return;
    if (!_speechReady) {
      await _bootstrapSpeech();
    }
    if (!_speechReady) {
      if (!mounted) return;
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.strings.locale == 'ar'
                  ? 'الميكروفون غير متاح'
                  : 'Microphone indisponible',
            ),
          ),
        );
      } else {
        final st = await Permission.microphone.status;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !st.isGranted
                  ? widget.strings.healthMicNeedPermission
                  : widget.strings.healthSpeechEngineUnavailable,
            ),
            action: st.isPermanentlyDenied
                ? SnackBarAction(
                    label: widget.strings.settings,
                    onPressed: () => openAppSettings(),
                  )
                : null,
          ),
        );
      }
      return;
    }
    if (_listening) {
      await _finishSpeechFromMic(userPressedStop: true);
      return;
    }

    await _voice.stop();
    _lastSpeechText = '';
    _speechSessionSent = false;

    final localeId = await _resolveSpeechLocaleId();
    if (!mounted) return;

    setState(() => _listening = true);
    try {
      await _speech.listen(
        localeId: localeId,
        listenFor: const Duration(seconds: 120),
        pauseFor: const Duration(seconds: 6),
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
          onDevice: false,
        ),
        onResult: (res) {
          if (!mounted) return;
          final words = res.recognizedWords.trim();
          if (words.isNotEmpty) {
            _lastSpeechText = words;
          }
          if (res.finalResult && words.isNotEmpty && !_speechSessionSent) {
            _speechSessionSent = true;
            setState(() => _listening = false);
            unawaited(_speech.stop());
            unawaited(_send(words));
          }
        },
      );
    } on stt.ListenFailedException {
      if (mounted) {
        setState(() => _listening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.strings.healthSpeechEngineUnavailable)),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _listening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.strings.healthSpeechEngineUnavailable)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.strings;
    final user = widget.userProfile;
    final aiMode = user == null
        ? null
        : ref.watch(aiInteractionModeProvider(user));
    final aiHealth = ref.watch(aiModuleHealthProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.healthChatTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Text(s.healthVoiceLang, style: theme.textTheme.labelSmall),
                const SizedBox(width: 4),
                SegmentedButton<HealthVoiceLang>(
                  segments: const [
                    ButtonSegment(value: HealthVoiceLang.fr, label: Text('FR')),
                    ButtonSegment(value: HealthVoiceLang.en, label: Text('EN')),
                  ],
                  selected: {_voiceLang},
                  onSelectionChanged: (set) {
                    if (_listening || _replyBusy) return;
                    setState(() => _voiceLang = set.first);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: theme.colorScheme.surfaceContainerLow,
            child: SwitchListTile(
              title: Text(s.healthVoiceAuto),
              subtitle: Text(
                _voiceLang == HealthVoiceLang.fr
                    ? 'Réponse lue automatiquement en français'
                    : 'Reply read aloud automatically in English',
              ),
              value: _autoSpeak,
              onChanged: (v) => setState(() => _autoSpeak = v),
            ),
          ),
          _HealthAiModuleBanner(health: aiHealth, mode: aiMode),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      widget.strings.isAr
                          ? 'معلومات عامة فقط — استشر طبيباً.'
                          : (_voiceLang == HealthVoiceLang.fr
                                ? _disclaimerBannerFr
                                : _disclaimerBannerEn),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  );
                }
                final m = _messages[i - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _Bubble(text: m.text, isUser: m.user),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_replyBusy) ...[
                    LinearProgressIndicator(
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 4),
                      child: Text(
                        s.healthChatThinking,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton.filledTonal(
                        onPressed: _replyBusy ? null : _toggleMic,
                        icon: Icon(_listening ? Icons.stop : Icons.mic_none),
                        tooltip: _listening
                            ? s.healthMicStop
                            : s.healthMicListen,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          enabled: !_replyBusy,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            if (!_replyBusy) unawaited(_send());
                          },
                          decoration: InputDecoration(
                            hintText: s.healthChatHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _replyBusy ? null : () => unawaited(_send()),
                        child: Text(s.healthChatSend),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
