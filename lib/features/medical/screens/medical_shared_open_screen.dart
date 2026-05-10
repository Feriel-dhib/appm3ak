import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/api_providers.dart';

class MedicalSharedOpenScreen extends ConsumerStatefulWidget {
  const MedicalSharedOpenScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<MedicalSharedOpenScreen> createState() =>
      _MedicalSharedOpenScreenState();
}

class _MedicalSharedOpenScreenState
    extends ConsumerState<MedicalSharedOpenScreen> {
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    final store = ref.read(localMedicalDocumentsStoreProvider);
    final local = await store.getByShareToken(widget.token);
    if (!mounted) return;
    if (local != null) {
      context.go('/medical-document/${local.id}');
      return;
    }
    final bytes = await ref
        .read(medicalDocumentsRepositoryProvider)
        .downloadSharedBytes(widget.token);
    if (bytes != null && bytes.isNotEmpty) {
      final doc = await store.saveSharedPreviewBytes(
        bytes: bytes,
        shareToken: widget.token,
      );
      if (!mounted) return;
      context.go('/medical-document/${doc.id}');
      return;
    }
    setState(() => _message = 'Document introuvable.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Document partagé')),
      body: Center(
        child: _message == null
            ? const CircularProgressIndicator()
            : Text(_message!),
      ),
    );
  }
}
