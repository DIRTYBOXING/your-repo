import 'package:flutter/foundation.dart';
import '../models/telemetry_data_model.dart';
import '../services/telemetry_service.dart';

class TelemetryController extends ChangeNotifier {
  final _service = TelemetryService();

  bool isLoading = true;
  String? error;
  TelemetryDataModel? data;

  Future<void> loadTelemetry() async {
    isLoading = true;
    notifyListeners();

    try {
      data = await _service.fetchAggregatedTelemetry();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}