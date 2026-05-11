// accessibility_ai_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Service Flutter qui appelle le backend M3ak (Groq + OSM)
// pour obtenir les scores d'accessibilité par type de handicap.
//
// Sources utilisées :
//   1. Internet (OSM + Google) — source principale existante
//   2. Communauté M3ak — avis des utilisateurs (backend port 3000)
//
// UTILISATION :
//   final result = await AccessibilityAIService.analyze(place);
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import 'accessibility_ai_platform_io.dart'
    if (dart.library.html) 'accessibility_ai_platform_web.dart';
import '../../data/api/endpoints.dart';
import '../../data/repositories/community_post_source.dart';

// ── Modèles ───────────────────────────────────────────────────────────────────

class HandicapScore {
  final int score;
  final String niveau;
  final List<String> details;
  final List<String> sources;

  const HandicapScore({
    required this.score,
    required this.niveau,
    required this.details,
    required this.sources,
  });

  factory HandicapScore.fromJson(Map<String, dynamic> j) => HandicapScore(
        score: (j['score'] as num?)?.toInt() ?? 0,
        niveau: j['niveau'] as String? ?? 'Non adapté',
        details: List<String>.from(j['details'] ?? []),
        sources: List<String>.from(j['sources'] ?? []),
      );

  static const Map<String, int> _colors = {
    'Excellent':  0xFF2A9F58,
    'Bon':        0xFF4A90D9,
    'Partiel':    0xFFE69D2A,
    'Non adapté': 0xFFD24C4C,
  };

  int get color => _colors[niveau] ?? 0xFF888888;
}

class AIAccessibilityResult {
  final String placeName;
  final int scoreGlobal;
  final HandicapScore fauteuilRoulant;
  final HandicapScore surdite;
  final HandicapScore cecite;
  final HandicapScore mobiliteReduite;
  final HandicapScore cognitif;
  final String resumeIA;
  final String confiance;
  final List<String> sourcesUtilisees;
  final Map<String, dynamic> osmTags;

  /// Posts de la communauté utilisés dans l'analyse (nouvelle source)
  final List<CommunityPostSource> communityPostsUsed;

  const AIAccessibilityResult({
    required this.placeName,
    required this.scoreGlobal,
    required this.fauteuilRoulant,
    required this.surdite,
    required this.cecite,
    required this.mobiliteReduite,
    required this.cognitif,
    required this.resumeIA,
    required this.confiance,
    required this.sourcesUtilisees,
    required this.osmTags,
    this.communityPostsUsed = const [],
  });

  factory AIAccessibilityResult.fromJson(
    Map<String, dynamic> j, {
    List<CommunityPostSource> communityPosts = const [],
  }) =>
      AIAccessibilityResult(
        placeName:       j['place_name'] as String? ?? '',
        scoreGlobal:     (j['score_global'] as num?)?.toInt() ?? 0,
        fauteuilRoulant: HandicapScore.fromJson(j['fauteuil_roulant'] ?? {}),
        surdite:         HandicapScore.fromJson(j['surdite'] ?? {}),
        cecite:          HandicapScore.fromJson(j['cecite'] ?? {}),
        mobiliteReduite: HandicapScore.fromJson(j['mobilite_reduite'] ?? {}),
        cognitif:        HandicapScore.fromJson(j['cognitif'] ?? {}),
        resumeIA:        j['resume_ia'] as String? ?? '',
        confiance:       j['confiance'] as String? ?? 'Faible',
        sourcesUtilisees: List<String>.from(j['sources_utilisees'] ?? []),
        osmTags:         j['osm_tags'] as Map<String, dynamic>? ?? {},
        communityPostsUsed: communityPosts,
      );

  HandicapScore scoreFor(String type) {
    switch (type) {
      case 'fauteuil': return fauteuilRoulant;
      case 'surdite':  return surdite;
      case 'cecite':   return cecite;
      case 'mobilite': return mobiliteReduite;
      case 'cognitif': return cognitif;
      default:         return fauteuilRoulant;
    }
  }

  /// True si des avis communauté ont été utilisés dans l'analyse
  bool get hasCommunitySource => communityPostsUsed.isNotEmpty;
}

// ── Service ───────────────────────────────────────────────────────────────────

class AccessibilityAIService {
  AccessibilityAIService._();

  /// Web / Android : [AppConfig.aiBaseUrl]. Sinon (ex. iOS simulateur) : localhost fixe.
  static String get _directAiBaseUrl {
    if (kIsWeb || accessibilityAiHostUsesAppConfigBase) {
      return AppConfig.aiBaseUrl;
    }
    return 'http://127.0.0.1:8002';
  }

  /// Analyse un lieu et retourne les scores IA.
  ///
  /// Sources combinées :
  ///   - OSM + Groq (via FastAPI port 8002, préfixe /ai/accessibility) — source 1
  ///   - Avis communauté M3ak (backend port 3000) — source 2
  static Future<AIAccessibilityResult?> analyze({
    required String placeName,
    required double latitude,
    required double longitude,
    bool wheelchairAccess = false,
    bool elevator = false,
    bool braille = false,
    bool audioAssistance = false,
    bool accessibleToilets = false,
    List<String> userComments = const [],
  }) async {
    // ── Source 2 : avis filtrés par lieu (GET …/community/posts?limit=200 + critères lieu)
    final communityPosts =
        await CommunityPostFetcher.fetchPostsForPlace(placeName);

    // Textes envoyés au backend IA (8000) dans `user_comments` pour enrichir le score
    final communityComments = communityPosts
        .map((p) => '[Communauté M3ak - ${p.typeLabel}] ${p.contenu}')
        .toList();

    final allComments = [...userComments, ...communityComments];

    final payload = <String, dynamic>{
      'place_name': placeName,
      'latitude': latitude,
      'longitude': longitude,
      'wheelchair_access': wheelchairAccess,
      'elevator': elevator,
      'braille': braille,
      'audio_assistance': audioAssistance,
      'accessible_toilets': accessibleToilets,
      'user_comments': allComments,
      'has_community_data': communityPosts.isNotEmpty,
      'community_posts_count': communityPosts.length,
    };
    final bodyJson = jsonEncode(payload);

    AIAccessibilityResult? parseOk(http.Response response) {
      if (response.statusCode != 200) return null;
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final sources = List<String>.from(data['sources_utilisees'] ?? []);
        if (communityPosts.isNotEmpty &&
            !sources.contains('Communauté M3ak')) {
          sources.add('Communauté M3ak');
          data['sources_utilisees'] = sources;
        }
        return AIAccessibilityResult.fromJson(
          data,
          communityPosts: communityPosts,
        );
      } catch (_) {
        return null;
      }
    }

    // 1) FastAPI direct ([_directAiBaseUrl] : aiBaseUrl sur Web/Android, sinon 127.0.0.1:8002)
    try {
      final r = await http
          .post(
            Uri.parse(
              '$_directAiBaseUrl/ai/accessibility/analyze',
            ),
            headers: {'Content-Type': 'application/json'},
            body: bodyJson,
          )
          .timeout(const Duration(seconds: 45));
      final out = parseOk(r);
      if (out != null) return out;
    } catch (_) {}

    // 2) Repli NestJS (proxy vers la même IA si FastAPI n’est pas joignable)
    try {
      final r = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}${Endpoints.accessibilityAnalyze}'),
            headers: {'Content-Type': 'application/json'},
            body: bodyJson,
          )
          .timeout(const Duration(seconds: 45));
      final out = parseOk(r);
      if (out != null) return out;
    } catch (_) {}

    return null;
  }

  /// Vérifie si le backend IA est disponible
  static Future<bool> isBackendOnline() async {
    try {
      final r = await http
          .get(Uri.parse('$_directAiBaseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Vérifie si le backend communauté (NestJS) est disponible
  static Future<bool> isCommunityBackendOnline() async {
    try {
      final r = await http
          .get(Uri.parse('${AppConfig.apiBaseUrl}/community/posts?limit=1'))
          .timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
