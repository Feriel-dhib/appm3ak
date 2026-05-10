import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models/medical_document_model.dart';

const _prefsKey = 'medical_documents_index_v1';
const _docsSubDir = 'medical_docs';

/// Stockage local sécurisé des documents numérisés (fichiers + index JSON).
class LocalMedicalDocumentsStore {
  static const shareScheme = 'ma3ak://meddoc/';

  static String canonicalShareToken(String token) {
    final s = token.trim().toLowerCase().replaceAll('-', '');
    if (RegExp(r'^[a-f0-9]{32}$').hasMatch(s)) return s;
    return token.trim().toLowerCase();
  }

  static String? parseShareTokenFromScan(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    final uri = Uri.tryParse(s);
    if (uri != null &&
        uri.scheme == 'ma3ak' &&
        uri.host.toLowerCase() == 'meddoc') {
      final segs = uri.pathSegments.where((e) => e.isNotEmpty).toList();
      if (segs.isNotEmpty) return canonicalShareToken(segs.last);
      final path = uri.path.replaceFirst(RegExp(r'^/+'), '');
      if (path.isNotEmpty) return canonicalShareToken(path);
    }
    final lower = s.toLowerCase();
    if (lower.startsWith(shareScheme.toLowerCase())) {
      return canonicalShareToken(s.substring(shareScheme.length));
    }
    if (RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(s)) return canonicalShareToken(s);
    return null;
  }

  Future<Directory> _docsDir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, _docsSubDir));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<List<MedicalDocumentModel>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => MedicalDocumentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveIndex(List<MedicalDocumentModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<String> resolveAbsolutePath(MedicalDocumentModel doc) async {
    final root = await getApplicationDocumentsDirectory();
    return p.join(root.path, doc.localRelativePath);
  }

  Future<MedicalDocumentModel?> getById(String id) async {
    final items = await list();
    for (final d in items) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<MedicalDocumentModel?> getByShareToken(String token) async {
    final want = canonicalShareToken(token);
    if (want.isEmpty) return null;
    final items = await list();
    for (final d in items) {
      if (canonicalShareToken(d.shareToken) == want) return d;
    }
    return null;
  }

  Future<MedicalDocumentModel> saveProcessedImage({
    required Uint8List bytes,
    required String title,
    String? ocrText,
  }) async {
    final id = const Uuid().v4();
    final shareToken = const Uuid().v4().replaceAll('-', '');
    final fileName = '$id.jpg';
    final dir = await _docsDir();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    final relative = p.join(_docsSubDir, fileName);
    final doc = MedicalDocumentModel(
      id: id,
      shareToken: shareToken,
      title: title.trim().isEmpty ? 'Document médical' : title.trim(),
      localRelativePath: relative,
      ocrText: ocrText,
      cloudSynced: false,
      createdAt: DateTime.now(),
    );
    final items = await list()
      ..add(doc);
    await _saveIndex(items);
    return doc;
  }

  Future<void> updateDocument(MedicalDocumentModel doc) async {
    final items = await list();
    final i = items.indexWhere((d) => d.id == doc.id);
    if (i >= 0) {
      items[i] = doc;
    } else {
      items.add(doc);
    }
    await _saveIndex(items);
  }

  Future<void> delete(String id) async {
    final items = await list();
    MedicalDocumentModel? removed;
    final kept = <MedicalDocumentModel>[];
    for (final d in items) {
      if (d.id == id) {
        removed = d;
      } else {
        kept.add(d);
      }
    }
    if (removed != null) {
      try {
        final path = await resolveAbsolutePath(removed);
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    await _saveIndex(kept);
  }

  Future<MedicalDocumentModel> saveSharedPreviewBytes({
    required Uint8List bytes,
    required String shareToken,
    String title = 'Document partagé',
  }) async {
    final id = 'shared_${const Uuid().v4()}';
    final fileName = '$id.jpg';
    final dir = await _docsDir();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    final relative = p.join(_docsSubDir, fileName);
    final doc = MedicalDocumentModel(
      id: id,
      shareToken: shareToken,
      title: title,
      localRelativePath: relative,
      cloudSynced: true,
      createdAt: DateTime.now(),
    );
    final items = await list()
      ..add(doc);
    await _saveIndex(items);
    return doc;
  }
}
