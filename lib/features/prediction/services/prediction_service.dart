class PredictionService {
  Future<Map<String, dynamic>> loadPrediction(String eventId) async {
    return {
      'eventId': eventId,
      'probabilityA': 0.5,
      'probabilityB': 0.5,
      'confidence': 0.0,
    };
  }
}
