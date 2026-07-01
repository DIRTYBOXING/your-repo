import '../models/health_document_model.dart';
import '../../api_service.dart';

class HealthDocumentRepository {
  final ApiService apiService;

  HealthDocumentRepository({required this.apiService});

  Future<List<HealthDocumentModel>> getDocuments() async {
    final data = await apiService.callFunction('getMedicalDocuments');
    final List<dynamic> docList = data['documents'] ?? [];
    return docList
        .map((e) => HealthDocumentModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> uploadDocument(String filename, String docType) async {
    await apiService.callFunction('uploadMedicalDocument', {
      'filename': filename,
      'docType': docType,
    });
  }
}
