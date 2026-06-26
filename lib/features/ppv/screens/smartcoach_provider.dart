import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/smartcoach_api_service.dart';

final smartCoachProvider = FutureProvider.family<String, String>((
  ref,
  message,
) async {
  return SmartCoachApiService.sendMessage(message);
});
