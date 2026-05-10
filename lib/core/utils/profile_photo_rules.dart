import 'dart:io';

import 'package:path/path.dart' as p;

/// Limite API : 5 Mo (PATCH /user/me/photo).
const int kProfilePhotoMaxBytes = 5 * 1024 * 1024;

const Set<String> _kProfilePhotoExtensions = {
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
  '.webp',
};

/// Types autorisés côté API : jpeg, png, gif, webp.
bool isProfilePhotoFileAllowed(File file) {
  final ext = p.extension(file.path).toLowerCase();
  if (!_kProfilePhotoExtensions.contains(ext)) return false;
  try {
    if (file.lengthSync() > kProfilePhotoMaxBytes) return false;
  } on Object {
    return false;
  }
  return true;
}

/// Règles d’affichage : URL absolue, ou chemin `uploads/...` relatif à [apiBaseUrl].
/// [apiBaseUrl] : `AppConfig.apiBaseUrl` (sans slash final de préférence).
String resolveProfilePhotoDisplayUrl(String? photoProfil, String apiBaseUrl) {
  if (photoProfil == null || photoProfil.trim().isEmpty) return '';
  final raw = photoProfil.trim();
  final lower = raw.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return raw;
  }
  final base = apiBaseUrl.replaceAll(RegExp(r'/$'), '');
  if (raw.startsWith('uploads/')) {
    return '$base/$raw';
  }
  // Rétrocompat (tests / anciennes données) : nom de fichier seul → sous uploads/
  final noLeading = raw.startsWith('/') ? raw.substring(1) : raw;
  if (!noLeading.contains('/')) {
    return '$base/uploads/$noLeading';
  }
  return '$base/$noLeading';
}
