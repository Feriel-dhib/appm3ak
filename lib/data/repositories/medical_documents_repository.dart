import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../api/api_client.dart';
import '../api/endpoints.dart';

class MedicalDocumentsRepository {
  MedicalDocumentsRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<bool> uploadScan(
    File file, {
    required String title,
    required String shareToken,
  }) async {
    try {
      final form = FormData.fromMap({
        'title': title,
        'shareToken': shareToken,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: p.basename(file.path),
        ),
      });
      await _api.dio.post<void>(Endpoints.medicalDocuments, data: form);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Uint8List?> downloadSharedBytes(String shareToken) async {
    try {
      final response = await _api.dio.get<dynamic>(
        Endpoints.medicalDocumentShare(shareToken.trim()),
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data == null) return null;
      if (data is Uint8List) return data;
      if (data is List<int>) return Uint8List.fromList(data);
      return null;
    } catch (_) {
      return null;
    }
  }
}
