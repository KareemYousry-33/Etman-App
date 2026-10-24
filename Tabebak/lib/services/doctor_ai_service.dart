import 'dart:convert';
import 'package:http/http.dart' as http;

class DoctorAIService {
  static const String apiEndpoint = 'https://api.deepseek.com/chat/completions';
  static const String apiKey = 'sk-8d7ea47223ab490393d3baf94a1527a3';

  static Future<String> getResponse(String userMessage) async {
    try {
      // Prepare the message history with system and user messages
      final messages = [
        {
          "role": "system",
          "content": """أنت مساعد طبي ذكي اسمك 'طبيبك الذكي'. يجب أن تجيب دائماً باللغة العربية الفصحى البسيطة مهما كان سؤال المستخدم. أسلوبك ودود واحترافي وتشجيعي. إجاباتك قصيرة ومفيدة ومباشرة. لا تستخدم علامات التنسيق مثل * أو ** أو الإيموجي. عندما يسألك عن كيفية حجز موعد قل له: اذهب إلى قسم الأطباء واختر دكتوراً متخصصاً في حالتك واحجز معه موعداً. عندما يصف أعراضاً اذكر الأسباب المحتملة باللغة العربية واقترح التصرف المناسب بأسلوب دافئ ومطمئن.""",
        },
        {"role": "user", "content": userMessage},
      ];

      // Prepare the request body
      final requestBody = {
        "model": "deepseek-chat",
        "messages": messages,
        "stream": false,
      };

      print(
        "🔄 Sending request to DeepSeek API with body: ${jsonEncode(requestBody)}",
      );

      // Make the API request
      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      // Print the raw response
      print("📥 DeepSeek API Response Status: ${response.statusCode}");
      print("📥 DeepSeek API Response Body: ${response.body}");

      // Check if the request was successful
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Print the parsed response structure
        print("✅ DeepSeek API Parsed Response: $data");

        // Extract the assistant's response from the API response
        final assistantResponse = data['choices'][0]['message']['content'];
        print("💬 Assistant's Response: $assistantResponse");
        return assistantResponse;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return 'عذراً، حدث خطأ أثناء معالجة طلبك. يرجى المحاولة مرة أخرى.';
      }
    } catch (e) {
      print('❌ Exception in DoctorAIService: $e');
      return 'عذراً حدث خطأ في الاتصال. يرجى التحقق من الاتصال بالإنترنت والمحاولة مرة أخرى.';
    }
  }
}
