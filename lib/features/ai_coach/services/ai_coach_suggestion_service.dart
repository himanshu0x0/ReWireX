import '../../prediction/services/urge_prediction_service.dart';
import '../../prediction/services/relapse_prediction_service.dart';
import '../../stability/services/stability_service.dart';

class AICoachSuggestionService {

  final UrgePredictionService _urgeService = UrgePredictionService();
  final RelapsePredictionService _relapseService = RelapsePredictionService();
  final StabilityService _stabilityService = StabilityService();

  Future<List<String>> generateSuggestions() async {

    final urge = await _urgeService.predictUrge();
    final relapse = await _relapseService.analyzeRelapseRisk();
    final stability = await _stabilityService.calculateStability();

    List<String> suggestions = [];

    if (urge.probability > 50) {
      suggestions.add("Why do my urges usually happen during ${urge.window}?");
      suggestions.add("What should I do during my high-risk window?");
    }

    if (relapse.probability > 50) {
      suggestions.add("Why is my relapse probability high today?");
      suggestions.add("How can I prevent relapse right now?");
    }

    if (stability.score < 60) {
      suggestions.add("How can I improve my behavioral stability?");
    }

    suggestions.add("How can I protect my current streak?");
    suggestions.add("What should I do when I feel urge?");

    return suggestions;
  }
}