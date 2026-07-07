import 'package:flutter_riverpod/flutter_riverpod.dart';

/// SmartCoach provider — calls the PPV SmartCoach API service.
/// The API service lives in lib/features/ppv/screens/smartcoach_api_service.dart.
final smartCoachProvider = FutureProvider.family<String, String>((
  ref,
  message,
) async {
  // Stub response — wire to SmartCoachApiService when available in this build context.
  return 'SmartCoach received: $message';
});
