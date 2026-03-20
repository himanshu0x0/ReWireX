// lib/features/ai/models/ai_guidance_model.dart

/// 🤖 AI Guidance Model
class AIGuidanceModel {
  final String tone;    // "Alert" | "Firm" | "Supportive" | "Neutral"
  final String message;
  final String action;  // button label

  const AIGuidanceModel({
    required this.tone,
    required this.message,
    required this.action,
  });
}