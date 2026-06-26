import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/search_result_model.dart';
import '../services/search_service.dart';

class SearchController extends ChangeNotifier {
  final _service = SearchService();
  
  bool isLoading = false;
  String? error;
  List<SearchResultModel> results = [];
  Timer? _debounceTimer;

  void performSearch(String query, String filter) {
    if (query.isEmpty) {
      results = [];
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        results = await _service.search(query, filter);
      } catch (e) {
        error = e.toString();
      } finally {
        isLoading = false;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}