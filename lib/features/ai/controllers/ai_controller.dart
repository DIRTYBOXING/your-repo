import '../services/ai_service.dart';

class AiController {
  AiController(this.service);

  final AiService service;

  Future<String> ask(String prompt) => service.ask(prompt);
}
