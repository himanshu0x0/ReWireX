class AIDataRouter {

  static bool asksRecoveryScore(String text) {
    return text.contains("recovery score");
  }

  static bool asksUrgePrediction(String text) {
    return text.contains("urge prediction");
  }

  static bool asksBehavioralStability(String text) {
    return text.contains("behavioral stability");
  }

  static bool asksRelapseRisk(String text) {
    return text.contains("relapse risk");
  }

  static bool asksCurrentStreak(String text) {
    return text.contains("streak");
  }

}