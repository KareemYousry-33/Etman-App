import 'package:get/get.dart';
import '../services/gemini_service.dart';

class ChatController extends GetxController {
  final GeminiService _geminiService = Get.find<GeminiService>();
  
  var messages = <Map<String, String>>[].obs;
  var isLoading = false.obs;

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    messages.add({'role': 'user', 'text': text});
    isLoading.value = true;

    try {
      final response = await _geminiService.getGeminiResponse(text);
      messages.add({'role': 'assistant', 'text': response});
    } catch (e) {
      messages.add({'role': 'assistant', 'text': 'عذراً، حدث خطأ ما. يرجى المحاولة مرة أخرى.'});
    } finally {
      isLoading.value = false;
    }
  }

  void clearChat() {
    messages.clear();
  }
}
