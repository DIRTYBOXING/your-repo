import '../services/prediction_service.dart';

class PredictionController {
  PredictionController(this.service);

  final PredictionService service;

  Future<Map<String, dynamic>> load(String eventId) => service.loadPrediction(eventId);
}
