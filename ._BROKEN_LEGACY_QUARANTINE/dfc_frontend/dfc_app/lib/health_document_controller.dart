import 'package:flutter/foundation.dart';
import '../repositories/health_document_repository.dart';
import '../state/health_document_state.dart';

class HealthDocumentController extends ChangeNotifier {
  final HealthDocumentRepository repository;

  HealthDocumentState _state = HealthDocumentInitial();
  HealthDocumentState get state => _state;

  HealthDocumentController({required this.repository});

  Future<void> loadDocuments() async {
    _state = HealthDocumentLoading();
    notifyListeners();

    try {
      final docs = await repository.getDocuments();
      _state = HealthDocumentLoaded(docs);
    } catch (e) {
      _state = HealthDocumentError(e.toString());
    } finally {
      notifyListeners();
    }
  }

  Future<void> uploadDocument(String filename, String docType) async {
    try {
      await repository.uploadDocument(filename, docType);
      await loadDocuments(); // Refresh queue after upload
    } catch (e) {
      // Handled silently or propagated depending on requirements
    }
  }
}
