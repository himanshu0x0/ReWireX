/// 📈 Weekly Trend Model
/// Holds 7-day urge counts, emotion distribution,
/// average intensity, and a computed trend direction.
class WeeklyTrendModel {
  final List<int> dailyCounts; // index 0 = 6 days ago, index 6 = today
  final double averageIntensity;
  final Map<String, int> emotionDistribution;
  final String trendDirection; // "Rising" | "Stable" | "Decreasing"
  final int totalUrges;

  WeeklyTrendModel({
    required this.dailyCounts,
    required this.averageIntensity,
    required this.emotionDistribution,
    required this.trendDirection,
    required this.totalUrges,
  });

  /// Index (0–6) of the day with the most urges — computed from dailyCounts.
  int get peakDayIndex {
    int idx = 0;
    int max = 0;
    for (int i = 0; i < dailyCounts.length; i++) {
      if (dailyCounts[i] > max) {
        max = dailyCounts[i];
        idx = i;
      }
    }
    return idx;
  }

  /// Dominant emotion by highest count.
  String get dominantEmotion {
    if (emotionDistribution.isEmpty) return 'None';
    return emotionDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  factory WeeklyTrendModel.empty() => WeeklyTrendModel(
        dailyCounts: List.filled(7, 0),
        averageIntensity: 0,
        emotionDistribution: {},
        trendDirection: 'Stable',
        totalUrges: 0,
      );
}