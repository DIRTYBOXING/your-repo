import 'package:flutter/foundation.dart';
import '../repositories/moderation_repository.dart';
import '../state/moderation_state.dart';

class ModerationController extends ChangeNotifier {
  final ModerationRepository repo;

  ModerationState _state = ModerationInitial();
  ModerationState get state => _state;

  ModerationController({required this.repo});

  Future<void> loadReports() async {
    _state = ModerationLoading();
    notifyListeners();

    try {
      final reports = await repo.getReportedItems();
      _state = ModerationLoaded(reports);
    } catch (e) {
      _state = ModerationError(e.toString());
    } finally {
      notifyListeners();
    }
  }

  Future<void> resolve(
    String reportId,
    String action,
    String targetId,
    String type,
  ) async {
    // Perform action and instantly refresh the queue
    await repo.resolveReport(reportId, action, targetId, type);
    await loadReports();
  }
}
