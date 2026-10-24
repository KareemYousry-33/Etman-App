import 'dart:convert';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:etman/controllers/auth_controller.dart';

class GeminiService extends GetxService {
  late GenerativeModel _model;
  late ChatSession _chat;
  
  final String _apiKey = 'YOUR_API_KEY'; // User should provide or use env
  
  @override
  void onInit() {
    super.onInit();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
    _chat = _model.startChat();
  }

  /// Original method
  Future<String> getGeminiResponse(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'اعتذر، لم استطع فهم ذلك.';
    } catch (e) {
      return 'حدث خطأ في الاتصال بالذكاء الاصطناعي.';
    }
  }

  /// Alias for backward compatibility with existing UI screens
  Future<String> getResponse(String prompt, [List<dynamic>? history]) async {
    return getGeminiResponse(prompt);
  }
}
