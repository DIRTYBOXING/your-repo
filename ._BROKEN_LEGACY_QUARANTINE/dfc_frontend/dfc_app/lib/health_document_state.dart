import '../models/health_document_model.dart';

/// V12 STATE MACHINE: HEALTH DOCUMENTS
sealed class HealthDocumentState {}

class HealthDocumentInitial extends HealthDocumentState {}

class HealthDocumentLoading extends HealthDocumentState {}

class HealthDocumentLoaded extends HealthDocumentState {
  final List<HealthDocumentModel> documents;
  HealthDocumentLoaded(this.documents);
}

class HealthDocumentError extends HealthDocumentState {
  final String message;
  HealthDocumentError(this.message);
}
