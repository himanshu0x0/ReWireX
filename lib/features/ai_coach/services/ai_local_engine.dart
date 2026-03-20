class AILocalEngine {

  String generateLocalResponse(String message) {

    final text = message.toLowerCase();

    if (text.contains("urge")) {
      return "Urges are temporary signals from the brain. Try delaying the urge, breathing deeply, and changing your environment.";
    }

    if (text.contains("relapse")) {
      return "Relapse often happens when triggers and stress combine. Focus on small recovery steps and avoid known triggers.";
    }

    if (text.contains("night")) {
      return "Urges often increase at night because the brain is tired and self-control decreases.";
    }

    if (text.contains("hello") || text.contains("hi")) {
      return "Hello 👋 I'm your AI recovery coach. Ask me about urges, relapse prevention, or recovery strategies.";
    }

    return "I'm here to help with urges and recovery. Try asking something about your recovery journey.";
  }
}