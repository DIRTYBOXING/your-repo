class AiService {
  Future<String> ask(String prompt) async {
    if (prompt.trim().isEmpty) {
      return 'No prompt provided.';
    }
    return 'AI response placeholder for: $prompt';
  }
}
