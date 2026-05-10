import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Export du scan en PDF partageable.
class MedicalSharePdf {
  MedicalSharePdf._();

  static Future<void> shareDocumentImageAsPdf({
    required String imagePath,
    required String title,
  }) async {
    final bytes = await File(imagePath).readAsBytes();
    final image = pw.MemoryImage(bytes);
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) =>
            pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ),
    );
    final out = await doc.save();
    final dir = await getTemporaryDirectory();
    var safe = title.replaceAll(RegExp(r'[^\w\- ]'), '_').trim();
    safe = safe.replaceAll(RegExp(r'_+'), '_');
    if (safe.isEmpty) safe = 'document_ma3ak';
    final file = File('${dir.path}/$safe.pdf');
    await file.writeAsBytes(out);
    await Share.shareXFiles([XFile(file.path)], text: title);
  }
}
