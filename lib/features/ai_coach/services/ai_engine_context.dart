// lib/features/ai_coach/services/ai_engine_context.dart

import 'package:flutter/foundation.dart';

// ── Analytics ─────────────────────────────────────────────────────────────────
import 'package:rewirex/features/analytics/services/habit_loop_service.dart';
import 'package:rewirex/features/analytics/services/heatmap_service.dart';
import 'package:rewirex/features/analytics/services/trend_analytics_service.dart';
import 'package:rewirex/features/analytics/services/trigger_mapping_service.dart';
import 'package:rewirex/features/analytics/services/habit_pattern_service.dart';

// ── Risk / Prediction / Stability (model files are in /models/) ───────────────
import 'package:rewirex/features/risk/services/risk_prediction_service.dart';
import 'package:rewirex/features/prediction/services/relapse_prediction_service.dart';
import 'package:rewirex/features/prediction/services/urge_prediction_service.dart';
import 'package:rewirex/features/stability/services/stability_service.dart';

// ── Streak ────────────────────────────────────────────────────────────────────
import 'package:rewirex/features/streak/services/streak_service.dart';

// ── AI meta ───────────────────────────────────────────────────────────────────
import 'package:rewirex/features/ai/services/recovery_score_service.dart';
import 'package:rewirex/features/ai/services/behavior_pattern_service.dart';

class AIEngineContext {
  final RiskPredictionService      _riskService         = RiskPredictionService();
  final RelapsePredictionService   _relapseService      = RelapsePredictionService();
  final StabilityService           _stabilityService    = StabilityService();
  final StreakService               _streakService       = StreakService();
  final UrgePredictionService      _urgeService         = UrgePredictionService();
  final HabitLoopService           _habitLoopService    = HabitLoopService();
  final HeatmapService             _heatmapService      = HeatmapService();
  final TrendAnalyticsService      _trendService        = TrendAnalyticsService();
  final TriggerMappingService      _triggerService      = TriggerMappingService();
  final HabitPatternService        _habitPatternService = HabitPatternService();
  final RecoveryScoreService       _recoveryScoreService   = RecoveryScoreService();
  final BehaviorPatternService     _behaviorPatternService = BehaviorPatternService();

  Future<Map<String, dynamic>> collectEngineData() async {
    try {
      final results = await Future.wait([
        /* 0 */ _riskService.analyzeRisk().catchError((_) => null),
        /* 1 */ _relapseService.analyzeRelapseRisk().catchError(
                    (_) => const RelapsePredictionModel(probability: 0, level: 'Low')),
        /* 2 */ _stabilityService.calculateStability().catchError(
                    (_) => const StabilityModel(score: 50, level: 'Moderate')),
        /* 3 */ _urgeService.predictUrge().catchError(
                    (_) => const UrgePredictionModel(
                        prediction: 'Low', probability: 10, window: 'next 2 hours')),
        /* 4 */ _habitLoopService.detectHabitLoop().catchError((_) => null),
        /* 5 */ _heatmapService.getHourlyHeatmap().catchError((_) => <int, int>{}),
        /* 6 */ _trendService.getWeeklyTrend().catchError((_) => null),
        /* 7 */ _triggerService.detectTriggerPattern().catchError((_) => null),
        /* 8 */ _habitPatternService.analyzePatterns().catchError((_) => null),
        /* 9 */ _recoveryScoreService.calculateRecoveryScore().catchError(
                    (_) => const RecoveryScoreModel(score: 0, level: 'Unknown')),
        /* 10*/ _behaviorPatternService.analyzeBehaviorPattern().catchError((_) => null),
      ]);

      final risk            = results[0]  as RiskModel?;
      final relapse         = results[1]  as RelapsePredictionModel;
      final stability       = results[2]  as StabilityModel;
      final urge            = results[3]  as UrgePredictionModel;
      final habitLoop       = results[4];
      final heatmapRaw      = results[5]  as Map<dynamic, dynamic>?;
      final trend           = results[6];
      final triggerMap      = results[7];
      final habitPattern    = results[8];
      final recoveryScore   = results[9]  as RecoveryScoreModel;
      final behaviorPattern = results[10] as String?;

      final heatmap = _castIntMap(heatmapRaw);

      final streakModel = await _streakService
          .getStreak().first.catchError((_) => null as StreakModel?);

      final int currentStreak = streakModel?.currentStreak ?? 0;
      final int bestStreak    = streakModel?.longestStreak  ?? 0;

      final double relapseProbability = relapse.probability;
      final String relapseLevel       = relapse.level;
      final double recoveryScoreValue = recoveryScore.score;
      final String recoveryLevel      = recoveryScore.level;
      final String urgeLevel          = urge.prediction;
      final int    urgeProbability    = urge.probability;
      final String urgeWindow         = urge.window;
      final String currentRisk        = risk?.level       ?? 'Low';
      final double riskProbability    = risk?.probability ?? 0.0;

      final String habitInsight        = _field(habitLoop, 'insight',
          fb: 'Not enough data to detect habit loops yet.');
      final int    habitFreq           = _intField(habitLoop, 'frequency');
      final String habitTrigger        = _field(habitLoop, 'trigger',  fb: 'Unknown');
      final String habitSeverity       = _field(habitLoop, 'severity', fb: 'Low');
      final String habitRecommendation = _field(habitLoop, 'recommendation', fb: '');

      String heatmapPeak = 'Not available';
      if (heatmap.isNotEmpty) {
        int peakHour = 0, peakCount = 0;
        heatmap.forEach((h, c) { if (c > peakCount) { peakCount = c; peakHour = h; } });
        heatmapPeak = '${_fmtHour(peakHour)} ($peakCount urges logged)';
      }

      final String trendDirection  = _field(trend, 'trendDirection',  fb: 'Stable');
      final int    totalUrges      = _intField(trend, 'totalUrges');
      final double avgIntensity    = _doubleField(trend, 'averageIntensity');
      final String dominantEmotion = _computed(
        trend        != null ? _field(trend,         'dominantEmotion', fb: '') : '',
        habitPattern != null ? _field(habitPattern,  'dominantEmotion', fb: '') : '',
        fb: 'Unknown',
      );

      final String triggerName       = _field(triggerMap, 'trigger',     fb: 'None');
      final String triggerDesc       = _field(triggerMap, 'description', fb: '');
      final String triggerRiskLevel  = _field(triggerMap, 'riskLevel',   fb: 'Low');
      final String triggerAdvice     = _field(triggerMap, 'actionAdvice',fb: '');
      final int    triggerFrequency  = _intField(triggerMap, 'frequency');
      final int    triggerPeakHour   = _intField(triggerMap, 'peakHour');
      final String triggerPeakTime   = triggerPeakHour > 0 ? _fmtHour(triggerPeakHour) : 'Unknown';
      final String triggerConfidence = triggerRiskLevel != 'Low'
          ? 'Risk at $triggerName window: $triggerRiskLevel' : 'Not available';

      final String behavioralInsight   = _field(habitPattern, 'insight',         fb: 'Not available');
      final String dominantTimeBlock   = _field(habitPattern, 'dominantTimeBlock',fb: 'Unknown');
      final String dominantUrgeType    = _field(habitPattern, 'dominantUrgeType', fb: 'Unknown');
      final double avgUrgeIntensity    = _doubleField(habitPattern, 'averageIntensity');
      final String intensityTrend      = _field(habitPattern, 'intensityTrend',   fb: 'Stable');
      final double behavioralRiskScore = _doubleField(habitPattern, 'riskScore');
      final double behavioralStability = stability.score;
      final String behavioralStabilityLevel = stability.level;

      final String emotionDistribution = stability.emotionDistribution != null
          ? stability.emotionDistribution!.entries
              .map((e) => '${e.key}: ${e.value}').join(', ')
          : 'Not available';

      final bool   preRelapseActive  = relapseProbability >= 60 ||
          currentRisk == 'Critical' || currentRisk == 'High';
      final String preRelapseWarning = preRelapseActive ? 'Active' : 'Inactive';

      final bool   guardianActive = relapseProbability >= 80 || currentRisk == 'Critical';
      final String guardianMode   = guardianActive ? 'Active' : 'Inactive';

      final String aiGuidance = _buildGuidance(
        relapseProbability: relapseProbability,
        riskLevel:          currentRisk,
        urgeLevel:          urgeLevel,
        trendDirection:     trendDirection,
        habitSeverity:      habitSeverity,
      );

      return {
        'currentRisk':             currentRisk,
        'currentRiskProbability':  riskProbability,
        'relapseProbability':      relapseProbability,
        'relapseLevel':            relapseLevel,
        'recoveryScore':           recoveryScoreValue,
        'recoveryLevel':           recoveryLevel,
        'currentStreak':           currentStreak,
        'bestStreak':              bestStreak,
        'urgePrediction':            urgeLevel,
        'urgePredictionProbability': urgeProbability,
        'urgePredictionWindow':      urgeWindow,
        'sevenDayUrgeTrend':   trendDirection,
        'weeklyTotalUrges':    totalUrges,
        'weeklyAvgIntensity':  avgIntensity,
        'urgeHeatmap':         heatmapPeak,
        'habitLoopInsight':        habitInsight,
        'habitLoopFrequency':      habitFreq,
        'habitLoopTrigger':        habitTrigger,
        'habitLoopSeverity':       habitSeverity,
        'habitLoopRecommendation': habitRecommendation,
        'triggerMapping':      triggerName,
        'triggerDescription':  triggerDesc,
        'triggerRiskLevel':    triggerRiskLevel,
        'triggerAdvice':       triggerAdvice,
        'triggerFrequency':    triggerFrequency,
        'triggerPeakHour':     triggerPeakHour,
        'triggerPeakTime':     triggerPeakTime,
        'triggerTopConfidence':triggerConfidence,
        'behavioralPattern':            behaviorPattern ?? 'Not available',
        'behavioralInsight':            behavioralInsight,
        'behavioralPatternConfidence':  behavioralRiskScore.toStringAsFixed(0),
        'dominantTimeBlock':            dominantTimeBlock,
        'dominantUrgeType':             dominantUrgeType,
        'avgUrgeIntensity':             avgUrgeIntensity,
        'intensityTrend':               intensityTrend,
        'behavioralRiskScore':          behavioralRiskScore,
        'behavioralStability':          behavioralStability,
        'behavioralStabilityLevel':     behavioralStabilityLevel,
        'emotionDistribution':  emotionDistribution,
        'dominantEmotion':      dominantEmotion,
        'preRelapseWarning':    preRelapseWarning,
        'guardianMode':         guardianMode,
        'aiGuidance':           aiGuidance,
      };
    } catch (e, st) {
      debugPrint('AIEngineContext error: $e\n$st');
      return _fallback();
    }
  }

  Map<int, int> _castIntMap(Map<dynamic, dynamic>? raw) {
    if (raw == null) return {};
    final out = <int, int>{};
    raw.forEach((k, v) {
      final ki = k is int ? k : int.tryParse(k.toString());
      final vi = v is int ? v : int.tryParse(v.toString());
      if (ki != null && vi != null) out[ki] = vi;
    });
    return out;
  }

  String _field(dynamic obj, String name, {String fb = ''}) {
    if (obj == null) return fb;
    try {
      switch (name) {
        case 'insight':          return (obj.insight          as String?) ?? fb;
        case 'trigger':          return (obj.trigger          as String?) ?? fb;
        case 'behavior':         return (obj.behavior         as String?) ?? fb;
        case 'severity':         return (obj.severity         as String?) ?? fb;
        case 'recommendation':   return (obj.recommendation   as String?) ?? fb;
        case 'trendDirection':   return (obj.trendDirection   as String?) ?? fb;
        case 'dominantEmotion':  return (obj.dominantEmotion  as String?) ?? fb;
        case 'description':      return (obj.description      as String?) ?? fb;
        case 'riskLevel':        return (obj.riskLevel        as String?) ?? fb;
        case 'actionAdvice':     return (obj.actionAdvice     as String?) ?? fb;
        case 'intensityTrend':   return (obj.intensityTrend   as String?) ?? fb;
        case 'dominantTimeBlock':return (obj.dominantTimeBlock as String?) ?? fb;
        case 'dominantUrgeType': return (obj.dominantUrgeType  as String?) ?? fb;
      }
    } catch (_) {}
    return fb;
  }

  int _intField(dynamic obj, String name) {
    if (obj == null) return 0;
    try {
      switch (name) {
        case 'frequency':  return (obj.frequency  as int?) ?? 0;
        case 'peakHour':   return (obj.peakHour   as int?) ?? 0;
        case 'totalUrges': return (obj.totalUrges as int?) ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  double _doubleField(dynamic obj, String name) {
    if (obj == null) return 0.0;
    try {
      switch (name) {
        case 'averageIntensity': return (obj.averageIntensity as num?)?.toDouble() ?? 0.0;
        case 'riskScore':        return (obj.riskScore        as num?)?.toDouble() ?? 0.0;
      }
    } catch (_) {}
    return 0.0;
  }

  String _computed(String a, String b, {required String fb}) {
    if (a.isNotEmpty) return a;
    if (b.isNotEmpty) return b;
    return fb;
  }

  String _fmtHour(int hour) {
    final s = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:00 $s';
  }

  String _buildGuidance({
    required double relapseProbability,
    required String riskLevel,
    required String urgeLevel,
    required String trendDirection,
    required String habitSeverity,
  }) {
    if (relapseProbability >= 90) {
      return 'Critical relapse risk — activate emergency prevention, avoid all known triggers, and contact your support network now.';
    }
    if (relapseProbability >= 85) {
      return 'High relapse risk detected. Stay connected to your recovery plan and avoid high-risk environments today.';
    }
    if (relapseProbability >= 60 || riskLevel == 'High' || riskLevel == 'Critical') {
      return 'Moderate-to-high risk detected. Stay mindful of urges and follow your planned recovery routine closely today.';
    }
    if (trendDirection == 'Rising') {
      return 'Your urge trend is rising this week. Strengthen daily habits and consider checking in with your support system.';
    }
    if (habitSeverity == 'High' || urgeLevel == 'High' || urgeLevel == 'Critical') {
      return 'Habit loop signals are strong today. Interrupt the pattern early by changing your environment or starting a replacement activity.';
    }
    return 'Your recovery signals look stable. Maintain your streak, follow your daily routine, and stay aware of potential triggers.';
  }

  Map<String, dynamic> _fallback() => {
    'currentRisk': 'Not available', 'currentRiskProbability': 0.0,
    'relapseProbability': 0.0, 'relapseLevel': 'Low',
    'recoveryScore': 0.0, 'recoveryLevel': 'Unknown',
    'currentStreak': 0, 'bestStreak': 0,
    'urgePrediction': 'Not available', 'urgePredictionProbability': 0,
    'urgePredictionWindow': 'next 2 hours',
    'sevenDayUrgeTrend': 'Stable', 'weeklyTotalUrges': 0, 'weeklyAvgIntensity': 0.0,
    'urgeHeatmap': 'Not available',
    'habitLoopInsight': 'Not available', 'habitLoopFrequency': 0,
    'habitLoopTrigger': 'Unknown', 'habitLoopSeverity': 'Low', 'habitLoopRecommendation': '',
    'triggerMapping': 'None', 'triggerDescription': '', 'triggerRiskLevel': 'Low',
    'triggerAdvice': '', 'triggerFrequency': 0, 'triggerPeakHour': 0,
    'triggerPeakTime': 'Unknown', 'triggerTopConfidence': 'Not available',
    'behavioralPattern': 'Not available', 'behavioralInsight': 'Not available',
    'behavioralPatternConfidence': '0', 'dominantTimeBlock': 'Unknown',
    'dominantUrgeType': 'Unknown', 'avgUrgeIntensity': 0.0, 'intensityTrend': 'Stable',
    'behavioralRiskScore': 0.0, 'behavioralStability': 0.0, 'behavioralStabilityLevel': 'Unknown',
    'emotionDistribution': 'Not available', 'dominantEmotion': 'Unknown',
    'preRelapseWarning': 'Inactive', 'guardianMode': 'Inactive',
    'aiGuidance': 'Stay focused on your recovery today. Log your urges and maintain your streak.',
  };
}