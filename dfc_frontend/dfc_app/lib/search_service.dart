import '../models/search_result_model.dart';

class SearchService {
  Future<List<SearchResultModel>> search(String query, String filter) async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (query.isEmpty) return [];

    // V12 Simulated Payload
    return [
      SearchResultModel(
        id: '1',
        title: 'Heath Ewart',
        subtitle: 'The Punisher',
        type: 'FIGHTERS',
        imageUrl:
            'https://ui-avatars.com/api/?name=Heath+Ewart&background=0A0E17&color=00E5FF',
        metadata: '14-2-0',
        extra: 'Lightweight',
      ),
      SearchResultModel(
        id: '2',
        title: 'DFC 2: REDEMPTION',
        subtitle: 'SAT, OCT 14 • MELBOURNE ARENA',
        type: 'EVENTS',
        imageUrl: '',
        metadata: 'UPCOMING',
        extra: '',
      ),
    ];
  }
}
