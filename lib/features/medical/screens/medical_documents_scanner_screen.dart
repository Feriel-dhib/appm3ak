import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../data/models/medical_document_model.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';
import '../services/medical_document_processing.dart';

class MedicalDocumentsScannerScreen extends ConsumerStatefulWidget {
  const MedicalDocumentsScannerScreen({super.key});

  @override
  ConsumerState<MedicalDocumentsScannerScreen> createState() =>
      _MedicalDocumentsScannerScreenState();
}

class _MedicalDocumentsScannerScreenState
    extends ConsumerState<MedicalDocumentsScannerScreen> {
  final _picker = ImagePicker();
  List<MedicalDocumentModel> _docs = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final list = await ref.read(localMedicalDocumentsStoreProvider).list();
    if (mounted) {
      setState(() {
        _docs = list
          ..sort(
            (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
              a.createdAt ?? DateTime(1970),
            ),
          );
        _loading = false;
      });
    }
  }

  Future<bool> _ensureCameraPermission() async {
    if (kIsWeb) return true;
    var s = await Permission.camera.status;
    if (!s.isGranted) s = await Permission.camera.request();
    return s.isGranted;
  }

  Future<void> _importFromSource(ImageSource source) async {
    if (kIsWeb) return;
    if (source == ImageSource.camera && !await _ensureCameraPermission())
      return;
    setState(() => _busy = true);
    try {
      final x = await _picker.pickImage(source: source, imageQuality: 92);
      if (x == null) return;
      final raw = await x.readAsBytes();
      final enhanced = MedicalDocumentProcessing.enhanceDocumentBytes(raw);
      final title = await showDialog<String>(
        context: context,
        builder: (c) {
          final ctrl = TextEditingController(text: 'Ordonnance / analyse');
          return AlertDialog(
            title: const Text('Titre du document'),
            content: TextField(controller: ctrl),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, ctrl.text.trim()),
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      );
      if (title == null || !mounted) return;
      final store = ref.read(localMedicalDocumentsStoreProvider);
      final doc = await store.saveProcessedImage(bytes: enhanced, title: title);
      final path = await store.resolveAbsolutePath(doc);
      final ocr = await MedicalDocumentProcessing.extractTextFromFile(path);
      if (ocr != null && ocr.isNotEmpty) {
        await store.updateDocument(doc.copyWith(ocrText: ocr));
      }
      final ok = await ref
          .read(medicalDocumentsRepositoryProvider)
          .uploadScan(File(path), title: title, shareToken: doc.shareToken);
      if (ok) {
        await store.updateDocument(doc.copyWith(cloudSynced: true));
      }
      await _refresh();
      if (!mounted) return;
      context.push('/medical-document/${doc.id}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openQrScan() async {
    if (kIsWeb) return;
    if (!await _ensureCameraPermission()) return;
    if (!mounted) return;
    final token = await context.push<String>('/medical-scan-qr');
    if (token == null || token.isEmpty || !mounted) return;
    final store = ref.read(localMedicalDocumentsStoreProvider);
    final local = await store.getByShareToken(token);
    if (local != null) {
      if (!mounted) return;
      context.push('/medical-document/${local.id}');
      return;
    }
    final bytes = await ref
        .read(medicalDocumentsRepositoryProvider)
        .downloadSharedBytes(token);
    if (bytes != null && bytes.isNotEmpty) {
      final doc = await store.saveSharedPreviewBytes(
        bytes: bytes,
        shareToken: token,
      );
      await _refresh();
      if (!mounted) return;
      context.push('/medical-document/${doc.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final isBeneficiary = user?.isBeneficiary ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isBeneficiary ? 'Documents médicaux' : 'Document partagé (QR)',
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (!_loading && _docs.isEmpty && isBeneficiary)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Aucun document. Utilisez caméra ou galerie.'),
                  ),
                ..._docs.map(
                  (d) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(d.title),
                      trailing: d.cloudSynced
                          ? const Icon(Icons.cloud_done, color: Colors.green)
                          : const Icon(Icons.phone_android),
                      onTap: () => context.push('/medical-document/${d.id}'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_busy)
            const ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBeneficiary)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _importFromSource(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Caméra'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _importFromSource(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galerie'),
                      ),
                    ),
                  ],
                ),
              if (isBeneficiary) const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _busy ? null : _openQrScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scanner QR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
