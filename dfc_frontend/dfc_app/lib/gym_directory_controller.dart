import 'package:flutter/foundation.dart';
import '../models/gym_directory_model.dart';
import '../services/gym_directory_service.dart';

class GymDirectoryController extends ChangeNotifier {
  final _service = GymDirectoryService();

  bool isLoading = false;
  List<GymDirectoryModel> gyms = [];

  Future<void> loadGyms() async {
    isLoading = true;
    notifyListeners();

    gyms = await _service.fetchGyms();

    isLoading = false;
    notifyListeners();
  }
}