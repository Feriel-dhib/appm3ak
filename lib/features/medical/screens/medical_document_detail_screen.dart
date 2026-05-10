import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../providers/api_providers.dart';
import '../services/medical_share_pdf.dart';

class MedicalDocumentDetailScreen extends ConsumerStatefulWidget {
  const MedicalDocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<MedicalDocumentDetailScreen> createState() =>
      _MedicalDocumentDetailScreenState();
}

class _MedicalDocumentDetailScreenState
    extends ConsumerState<MedicalDocumentDetailScreen> {
  dynamic _doc;
  String? _path;
  bool _loading = true;
  bool _sharingPdf = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final store = ref.read(localMedicalDocumentsStoreProvider);
    final d = await store.getById(widget.documentId);
    if (d != null) {
      final abs = await store.resolveAbsolutePath(d);
      if (mounted) {
        setState(() {
          _doc = d;
          _path = abs;
          _loading = false;
        });
      }
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    await ref
        .read(localMedicalDocumentsStoreProvider)
        .delete(widget.documentId);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _sharePdf() async {
    if (_path == null || _doc == null) return;
    setState(() => _sharingPdf = true);
    try {
      await MedicalSharePdf.shareDocumentImageAsPdf(
        imagePath: _path!,
        title: _doc.title as String,
      );
    } finally {
      if (mounted) setState(() => _sharingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_doc == null || _path == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Document')),
        body: const Center(child: Text('Document introuvable.')),
      );
    }
    final qrData = 'ma3ak://meddoc/${_doc.shareToken}';
    return Scaffold(
      appBar: AppBar(
        title: Text(_doc.title as String),
        actions: [
          IconButton(
            icon: _sharingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _sharingPdf ? null : _sharePdf,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Image.file(File(_path!), fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Partage accompagnant (QR)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Center(
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(qrData),
          if (_doc.ocrText != null &&
              (_doc.ocrText as String).trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Texte extrait (OCR)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(_doc.ocrText as String),
          ],
        ],
      ),
    );
  }
}
