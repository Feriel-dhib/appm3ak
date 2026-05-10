import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/storage_keys.dart';
import '../../../data/models/ai/adapt_models.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/ai_module_providers.dart';
import '../../../providers/auth_providers.dart';

/// Langue du moteur de reconnaissance (séparée de la langue d’affichage de l’UI).
enum ConversationCaptionListenLang { fr, ar, en }

/// Affiche en texte continu la parole de l’interlocuteur (usage sourds / malentendants).
class ConversationCaptionsScreen extends ConsumerStatefulWidget {
  const ConversationCaptionsScreen({super.key});

  @override
  ConsumerState<ConversationCaptionsScreen> createState() =>
      _ConversationCaptionsScreenState();
}

class _ConversationCaptionsScreenState
    extends ConsumerState<ConversationCaptionsScreen>
    with WidgetsBindingObserver {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ScrollController _scroll = ScrollController();

  bool _speechReady = false;

  /// Option utilisateur : boucle d’écoute active.
  bool _transcriptionOn = false;
  bool _sdkListening = false;
  bool _loopRunning = false;

  final List<String> _committed = [];
  String _partial = '';

  ConversationCaptionListenLang _listenLang = ConversationCaptionListenLang.fr;

  /// État permission micro (null = pas encore lu).
  PermissionStatus? _micPermission;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadSavedListenLang());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshMicPermissionAndWarmup());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      unawaited(_onAppResumed());
    }
  }

  Future<void> _onAppResumed() async {
    await _refreshMicPermission();
    if (!mounted) return;
    final mic = _micPermission;
    if (mic != null && !mic.isGranted && _transcriptionOn) {
      await _stopAll();
      _speechReady = false;
      if (mounted) setState(() {});
    }
    if (mic != null && mic.isGranted && !_speechReady) {
      await _bootstrapSpeech();
    }
  }

  Future<void> _refreshMicPermission() async {
    if (kIsWeb) {
      if (mounted) setState(() => _micPermission = PermissionStatus.denied);
      return;
    }
    final st = await Permission.microphone.status;
    if (mounted) setState(() => _micPermission = st);
  }

  /// Au premier affichage : lit la permission ; si déjà accordée, prépare SpeechToText.
  Future<void> _refreshMicPermissionAndWarmup() async {
    await _refreshMicPermission();
    if (!mounted) return;
    if (_micPermission?.isGranted == true) {
      await _bootstrapSpeech();
    }
  }

  Future<void> _requestMicFromBanner() async {
    final result = await Permission.microphone.request();
    if (!mounted) return;
    setState(() => _micPermission = result);
    if (result.isGranted) {
      _speechReady = false;
      await _bootstrapSpeech();
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadSavedListenLang() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StorageKeys.conversationCaptionLocale);
    ConversationCaptionListenLang lang = ConversationCaptionListenLang.fr;
    switch (raw) {
      case 'ar':
        lang = ConversationCaptionListenLang.ar;
        break;
      case 'en':
        lang = ConversationCaptionListenLang.en;
        break;
      default:
        final user = ref.read(authStateProvider).valueOrNull;
        switch (user?.preferredLanguage) {
          case PreferredLanguage.ar:
            lang = ConversationCaptionListenLang.ar;
            break;
          case PreferredLanguage.en:
            lang = ConversationCaptionListenLang.en;
            break;
          default:
            lang = ConversationCaptionListenLang.fr;
        }
    }
    if (!mounted) return;
    setState(() => _listenLang = lang);
  }

  Future<void> _saveListenLang(ConversationCaptionListenLang lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.conversationCaptionLocale, lang.name);
  }

  Future<bool> _ensureMicrophonePermission() async {
    if (kIsWeb) return false;
    var status = await Permission.microphone.status;
    if (status.isGranted) return true;
    status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _bootstrapSpeech() async {
    if (_speechReady) return;
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
        onStatus: (_) {},
        onError: (_) {
          if (mounted) setState(() => _sdkListening = false);
        },
      );
    } catch (_) {
      _speechReady = false;
    }
    if (mounted) setState(() {});
  }

  Future<String> _resolveSpeechLocaleId() async {
    try {
      final locales = await _speech.locales();
      final ids = locales.map((e) => e.localeId).toList();
      bool pickFr(String id) {
        final low = id.toLowerCase();
        return low.startsWith('fr') || low.contains('_fr');
      }

      bool pickAr(String id) {
        final low = id.toLowerCase();
        return low.startsWith('ar') || low.contains('_ar');
      }

      bool pickEn(String id) {
        final low = id.toLowerCase();
        return low.startsWith('en');
      }

      switch (_listenLang) {
        case ConversationCaptionListenLang.fr:
          for (final id in ids) {
            if (pickFr(id)) return id;
          }
          return 'fr_FR';
        case ConversationCaptionListenLang.ar:
          for (final id in ids) {
            if (pickAr(id)) return id;
          }
          return 'ar_SA';
        case ConversationCaptionListenLang.en:
          for (final id in ids) {
            if (pickEn(id)) return id;
          }
          return 'en_US';
      }
    } catch (_) {
      return switch (_listenLang) {
        ConversationCaptionListenLang.fr => 'fr_FR',
        ConversationCaptionListenLang.ar => 'ar_SA',
        ConversationCaptionListenLang.en => 'en_US',
      };
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _stopAll() async {
    _transcriptionOn = false;
    try {
      await _speech.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _sdkListening = false;
      });
    }
  }

  Future<void> _listenLoop() async {
    if (_loopRunning) return;
    _loopRunning = true;
    try {
      while (mounted && _transcriptionOn && _speechReady) {
        if (!_transcriptionOn) break;
        if (_speech.isListening) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          continue;
        }

        final localeId = await _resolveSpeechLocaleId();
        if (!mounted || !_transcriptionOn) break;

        setState(() => _sdkListening = true);
        try {
          await _speech.listen(
            localeId: localeId,
            listenFor: const Duration(seconds: 60),
            pauseFor: const Duration(seconds: 2),
            listenOptions: stt.SpeechListenOptions(
              listenMode: stt.ListenMode.dictation,
              partialResults: true,
              cancelOnError: false,
              onDevice: false,
            ),
            onResult: (r) {
              if (!mounted) return;
              final words = r.recognizedWords.trim();
              setState(() {
                if (r.finalResult) {
                  _partial = '';
                  if (words.isNotEmpty) {
                    _committed.add(words);
                  }
                } else {
                  _partial = words;
                }
              });
              _scrollToBottom();
            },
          );
        } catch (_) {
          if (mounted && _transcriptionOn) {
            await Future<void>.delayed(const Duration(milliseconds: 400));
          }
        }

        if (mounted) setState(() => _sdkListening = false);
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
    } finally {
      _loopRunning = false;
      if (mounted) setState(() => _sdkListening = false);
    }
  }

  Future<void> _onToggleTranscription(bool on) async {
    if (on) {
      await _bootstrapSpeech();
      if (!_speechReady) {
        if (!mounted) return;
        final mic = await Permission.microphone.status;
        if (!mounted) return;
        setState(() => _micPermission = mic);
        if (!mic.isGranted) {
          setState(() => _transcriptionOn = false);
          return;
        }
        final messenger = ScaffoldMessenger.of(context);
        final s = AppStrings.fromPreferredLanguage(
          ref.read(authStateProvider).valueOrNull?.preferredLanguage?.name,
        );
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(s.conversationCaptionsEngineUnavailable)),
        );
        setState(() => _transcriptionOn = false);
        return;
      }
      setState(() => _transcriptionOn = true);
      unawaited(_listenLoop());
    } else {
      await _stopAll();
      if (mounted) setState(() {});
    }
  }

  void _clearText() {
    setState(() {
      _committed.clear();
      _partial = '';
    });
  }

  Future<void> _onListenLangChanged(
    ConversationCaptionListenLang? value,
  ) async {
    if (value == null) return;
    setState(() => _listenLang = value);
    await _saveListenLang(value);
    if (_transcriptionOn) {
      await _speech.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transcriptionOn = false;
    unawaited(_speech.stop());
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final s = AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);
    final aiHealth = ref.watch(aiModuleHealthProvider);
    final aiMode = user == null
        ? null
        : ref.watch(aiInteractionModeProvider(user));

    return Scaffold(
      appBar: AppBar(title: Text(s.conversationCaptionsTitle)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                s.conversationCaptionsIntro,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _AiModuleStatusCard(health: aiHealth, mode: aiMode),
            ),
            if (_micPermission != null && !_micPermission!.isGranted)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Card(
                  color: theme.colorScheme.errorContainer.withValues(
                    alpha: 0.35,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.mic_off_outlined,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s.conversationCaptionsMicBannerBody,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_micPermission!.isPermanentlyDenied)
                          FilledButton.icon(
                            onPressed: () => openAppSettings(),
                            icon: const Icon(Icons.settings_outlined, size: 20),
                            label: Text(
                              s.conversationCaptionsOpenSettingsButton,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton(
                                onPressed: () =>
                                    unawaited(_requestMicFromBanner()),
                                child: Text(
                                  s.conversationCaptionsAllowMicButton,
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () => openAppSettings(),
                                child: Text(
                                  s.conversationCaptionsOpenSettingsButton,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<ConversationCaptionListenLang>(
                segments: [
                  ButtonSegment(
                    value: ConversationCaptionListenLang.fr,
                    label: const Text('FR'),
                  ),
                  ButtonSegment(
                    value: ConversationCaptionListenLang.ar,
                    label: const Text('عربي'),
                  ),
                  ButtonSegment(
                    value: ConversationCaptionListenLang.en,
                    label: const Text('EN'),
                  ),
                ],
                selected: {_listenLang},
                onSelectionChanged: (set) =>
                    unawaited(_onListenLangChanged(set.first)),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                s.conversationCaptionsLang,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SwitchListTile(
              title: Text(s.conversationCaptionsToggle),
              subtitle: _transcriptionOn
                  ? Text(
                      _sdkListening
                          ? s.conversationCaptionsListening
                          : s.conversationCaptionsPaused,
                    )
                  : null,
              value: _transcriptionOn,
              onChanged: (v) => unawaited(_onToggleTranscription(v)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: _clearText,
                icon: const Icon(Icons.delete_outline),
                label: Text(s.conversationCaptionsClear),
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: _committed.isEmpty && _partial.isEmpty
                    ? Center(
                        child: Text(
                          _transcriptionOn
                              ? s.conversationCaptionsListening
                              : s.conversationCaptionsEmpty,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView(
                        controller: _scroll,
                        children: [
                          SelectableText(
                            _committed.join('\n\n'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_partial.isNotEmpty) ...[
                            if (_committed.isNotEmpty)
                              const SizedBox(height: 16),
                            SelectableText(
                              _partial,
                              style: theme.textTheme.titleMedium?.copyWith(
                                height: 1.45,
                                color: theme.colorScheme.primary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiModuleStatusCard extends StatelessWidget {
  const _AiModuleStatusCard({required this.health, required this.mode});

  final AsyncValue<bool> health;
  final AsyncValue<AiInteractionMode>? mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final online = health.valueOrNull == true;
    final modeValue = mode?.valueOrNull;
    final modeText = switch (modeValue) {
      AiInteractionMode.voiceMode => 'mode vocal',
      AiInteractionMode.textMode => 'mode texte',
      AiInteractionMode.gestureMode => 'mode gestes',
      null => 'mode texte par défaut',
    };
    final statusText = health.when(
      data: (ok) => ok
          ? 'Module AI connecté: STT Whisper disponible, $modeText actif.'
          : 'Module AI indisponible: captions locales conservées.',
      loading: () => 'Vérification du module AI...',
      error: (error, stackTrace) =>
          'Module AI indisponible: captions locales conservées.',
    );

    return Card(
      color: online
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
          : theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              color: online
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                statusText,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
