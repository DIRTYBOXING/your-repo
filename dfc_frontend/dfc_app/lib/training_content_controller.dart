import 'package:flutter/foundation.dart';
import '../repositories/training_content_repository.dart';
import '../state/training_content_state.dart';

class TrainingContentController extends ChangeNotifier {
  final TrainingContentRepository repo;

  TrainingContentState _state = TrainingContentInitial();
  TrainingContentState get state => _state;

  TrainingContentController({required this.repo});

  Future<void> loadVault(String creatorId) async {
    _state = TrainingContentLoading();
    notifyListeners();

    try {
      final content = await repo.getTrainingVault(creatorId);
      _state = TrainingContentLoaded(content);
    } catch (e) {
      _state = TrainingContentError(e.toString());
    } finally {
      notifyListeners();
    }
  }
}
