import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../data/local_medical_documents_store.dart';

class MedicalQrScanScreen extends ConsumerStatefulWidget {
  const MedicalQrScanScreen({super.key});

  @override
  ConsumerState<MedicalQrScanScreen> createState() =>
      _MedicalQrScanScreenState();
}

class _MedicalQrScanScreenState extends ConsumerState<MedicalQrScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final b in capture.barcodes) {
      final token = LocalMedicalDocumentsStore.parseShareTokenFromScan(
        b.rawValue,
      );
      if (token != null && token.isNotEmpty) {
        _handled = true;
        if (mounted) context.pop(token);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner un QR médical'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              color: Colors.black87,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Pointez la caméra vers le QR document médical.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
