import 'package:flutter/foundation.dart';
import '../models/ppv_event_model.dart';
import '../services/ppv_service.dart';

class PpvController extends ChangeNotifier {
  final _service = PpvService();

  bool isLoading = false;
  PpvEventModel? event;

  Future<void> loadEvent(String id) async {
    isLoading = true;
    notifyListeners();

    event = await _service.fetchEvent(id);

    isLoading = false;
    notifyListeners();
  }
}
