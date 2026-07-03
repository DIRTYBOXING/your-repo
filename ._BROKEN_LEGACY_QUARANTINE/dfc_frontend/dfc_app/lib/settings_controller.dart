import 'package:flutter/foundation.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';

class SettingsController extends ChangeNotifier {
  final _service = SettingsService();

  bool isLoading = true;
  late SettingsModel settings;

  SettingsController() {
    _init();
  }

  Future<void> _init() async {
    settings = await _service.fetchUserSettings();
    isLoading = false;
    notifyListeners();
  }

  void togglePush(bool value) {
    settings = settings.copyWith(pushNotifications: value);
    notifyListeners();
    _service.updateSettings(settings);
  }

  void toggleEmail(bool value) {
    settings = settings.copyWith(emailUpdates: value);
    notifyListeners();
    _service.updateSettings(settings);
  }

  void toggleBiometrics(bool value) {
    settings = settings.copyWith(biometricLogin: value);
    notifyListeners();
    _service.updateSettings(settings);
  }
}
