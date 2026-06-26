import '../../api_service.dart';
import '../models/search_result_model.dart';

class SearchRepository {
  final ApiService api;
  SearchRepository({required this.api});

  Future<List<SearchResultModel>> performSearch(
    String query,
    String filter,
  ) async {
    final data = await api.callFunction("globalSearch", {
      "query": query,
      "filter": filter,
    });
    final list = data["results"] as List<dynamic>? ?? [];
    return list
        .map((e) => SearchResultModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
