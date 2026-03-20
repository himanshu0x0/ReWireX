import 'dart:convert';
import 'package:http/http.dart' as http;

class AILLMService {

  final String apiKey =
      "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";

  final String endpoint =
      "https://openrouter.ai/api/v1/chat/completions";

  Future<String?> generateResponse(
      String userMessage,
      List<Map<String, String>> history) async {

    try {

      final messages = [
        {
          "role": "system",
          "content": """
You are the official AI Coach for the ReWireX recovery platform.

ReWireX is an advanced addiction recovery assistant that includes systems such as:

• Recovery Score
• Urge Prediction Engine
• Behavioral Stability Engine
• Habit Loop Insight
• Trigger Mapping
• Emotion Distribution Analysis
• 7-Day Urge Trend
• Relapse Risk Analysis
• AI Daily Guidance
• Recovery Streak Tracking
• Behavioral Pattern Insights

Your responsibilities:

1. Help users understand addiction recovery concepts such as urges, relapse, triggers, habits, and emotional patterns.

2. Explain every ReWireX feature clearly if a user asks.

3. Provide supportive, motivational, and compassionate guidance.

4. If a user asks about a ReWireX feature, explain how it works and how it helps their recovery.

5. If a user asks unrelated questions (jokes, unrelated topics), politely redirect the conversation to recovery or the ReWireX app.

6. Always speak like a supportive recovery coach.

7. Keep explanations clear, friendly, and informative.

Never encourage harmful behavior. Always prioritize mental health support.
"""
        },

        ...history,

        {
          "role": "user",
          "content": userMessage
        }
      ];

      print("📤 Sending request to OpenRouter...");
      print("User message: $userMessage");

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
          "HTTP-Referer": "https://rewirex.app",
          "User-Agent": "RewireX-App"
        },
        body: jsonEncode({
          "model": "openai/gpt-3.5-turbo",
          "messages": messages,
          "temperature": 0.6,
          "max_tokens": 300
        }),
      );

      print("📥 Status Code: ${response.statusCode}");
      print("📥 Body: ${response.body}");

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);

      return data["choices"][0]["message"]["content"]
          .toString()
          .trim();

    } catch (e) {

      print("🚨 AI ERROR: $e");

      return null;

    }
  }
}