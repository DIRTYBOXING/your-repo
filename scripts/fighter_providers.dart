import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../sql/dataconnect/dfc_db.dart';
import 'fighter_service.dart';
import 'fighter_model.dart';

final fighterServiceProvider = Provider<FighterService>((ref) {
  return FighterService(DfcDb());
});

final fighterProvider = FutureProvider.family<Fighter?, String>((
  ref,
  id,
) async {
  final service = ref.watch(fighterServiceProvider);
  return service.getFighter(id);
});
