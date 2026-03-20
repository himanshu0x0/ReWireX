import 'dart:math';

import 'package:rewirex/features/ai/services/ai_memory_service.dart';
import 'package:rewirex/features/ai_coach/services/ai_engine_context.dart';

import 'ai_llm_service.dart';
import 'ai_local_engine.dart';
import 'ai_intent_router.dart';
import 'ai_emotion_router.dart';
import 'ai_crisis_router.dart';
import 'ai_data_router.dart';

class AICoachBrain {
  final AILLMService _llmService = AILLMService();
  final AILocalEngine _localEngine = AILocalEngine();
  final AIMemoryService _memoryService = AIMemoryService();
  final AIEngineContext _engineContext = AIEngineContext();

  final Random _random = Random();

  /// --------------------------------------------------
  /// ALL ENGINE KEYWORDS (VERY LARGE FOR DETECTION)
  /// --------------------------------------------------

  final List<String> featureKeywords = [
    "recovery score",
    "recovery system",
    "recovery engine",
    "recovery analytics",
    "recovery progress",
    "recovery metrics",
    "recovery dashboard",
    "relapse probability",
    "relapse prediction",
    "relapse risk",
    "relapse risk analysis",
    "pre relapse warning",
    "relapse detection",
    "urge prediction",
    "urge predictor",
    "urge trend",
    "urge trends",
    "7 day urge trend",
    "urge frequency",
    "urge patterns",
    "urge heatmap",
    "urge heatmap hourly",
    "hourly urge heatmap",
    "habit loop",
    "habit loop insight",
    "habit loop detection",
    "trigger",
    "triggers",
    "trigger mapping",
    "trigger analysis",
    "behavioral stability",
    "behavioural stability",
    "behavioral pattern",
    "behavior pattern",
    "behavior insight",
    "behavioral insight",
    "behavioral pattern insight",
    "emotion distribution",
    "emotional distribution",
    "emotion trends",
    "ai guidance",
    "ai daily guidance",
    "daily recovery guidance",
    "guardian mode",
    "guardian protection",
    "current risk",
    "risk level",
    "current streak",
    "recovery streak",
    "rewirex engines",
    "rewirex system",
    "rewirex features",
  ];

  /// -----------------------------
  /// RESPONSE POOLS
  /// -----------------------------

  final List<String> appreciationResponses = [
    "You're welcome! I'm glad I could help.",
    "Happy to support you anytime.",
    "I'm always here to help you on your recovery journey.",
    "You're welcome. Let me know if you need anything else.",
    "I'm glad that was helpful.",
    "No problem at all. I'm here whenever you need guidance.",
    "It's my pleasure to help.",
    "Always happy to support you.",
    "You're doing great by asking for help.",
    "Anytime! Feel free to ask more questions.",
    "Glad I could assist you.",
    "You're welcome. Keep moving forward.",
    "I'm here whenever you need support.",
    "Helping you is what I'm here for.",
    "Anytime you need guidance, just ask.",
  ];

  final List<String> frustrationResponses = [
    "Recovery can feel difficult sometimes, but every step forward matters.",
    "It's okay to struggle. Progress is built through small steps.",
    "You're not alone in this journey.",
    "Slips happen, but they don't erase your progress.",
    "What matters most is that you're trying again.",
    "Recovery takes patience and persistence.",
    "Even small improvements are meaningful progress.",
    "It's okay to feel frustrated. Let's focus on the next step.",
    "You're stronger than this moment feels.",
    "Every recovery journey has challenges.",
    "Keep going. Your effort matters.",
    "You're learning and growing through this process.",
    "Don't be too hard on yourself.",
    "Setbacks happen, but they don't define you.",
    "You're still moving forward.",
  ];

  final List<String> sadnessResponses = [
    "I'm really sorry you're feeling this way. You're not alone.",
    "It sounds like you're going through a tough moment.",
    "Your feelings matter, and it's okay to express them.",
    "You're not alone in this journey.",
    "Sometimes talking about it can help.",
    "You're stronger than you think.",
    "Even difficult days can pass.",
    "You're worthy of support and care.",
    "Recovery includes emotional ups and downs.",
    "Take things one step at a time.",
    "You deserve kindness and patience from yourself.",
    "You're doing your best, and that's important.",
    "It's okay to take a moment to breathe.",
    "Things can improve gradually.",
    "You're not facing this alone.",
  ];

  final List<String> anxietyResponses = [
    "It sounds like you're feeling stressed right now.",
    "Taking slow breaths can sometimes help calm your mind.",
    "It's okay to pause and take a moment for yourself.",
    "Stress can increase urges, so focusing on calmness helps.",
    "Try grounding yourself in the present moment.",
    "Your mind might just need a little rest.",
    "Sometimes stepping away from triggers helps.",
    "Let's focus on something small and manageable.",
    "Your feelings are valid.",
    "Even a short break can help reset your mind.",
    "You're doing the right thing by reaching out.",
    "Try slowing down your breathing for a moment.",
    "You don't have to handle everything at once.",
    "One step at a time.",
    "You're capable of getting through this moment.",
  ];

  final List<String> happinessResponses = [
    "That's wonderful to hear!",
    "Great job! Progress like this is important.",
    "You should feel proud of that progress.",
    "That's a great step forward.",
    "Moments like this strengthen recovery.",
    "Keep building these positive habits.",
    "You're making meaningful progress.",
    "That's really encouraging.",
    "Celebrate these wins.",
    "You're moving in the right direction.",
    "That's fantastic progress.",
    "Your effort is paying off.",
    "These victories matter.",
    "Keep up the great work.",
    "That's inspiring to hear.",
  ];

  /// -----------------------------
  /// CRISIS RESPONSES (~100)
  /// -----------------------------

  final List<String> crisisResponses = List.generate(
    100,
    (i) =>
        "I'm really sorry that you're feeling this way. Your life matters and you are not alone. "
        "If you're feeling overwhelmed or thinking about harming yourself, please consider reaching out "
        "to someone you trust or a mental health professional. Support is available and people care about you.",
  );

  /// Utility random selector
  String _randomResponse(List<String> responses) {
    return responses[_random.nextInt(responses.length)];
  }

  /// -----------------------------
  /// Helper formatters & safe getters
  /// -----------------------------
  ///
  /// These helpers are intentionally robust:
  ///  - search keys case-insensitively and by substrings
  ///  - handle nested maps returned from services
  ///  - parse numeric strings and fractional probabilities
  ///  - return the provided fallback when value is null/unparseable
  ///

  // Recursive search for a key (case-insensitive, substring) in maps.
  dynamic _searchRecursive(Map data, String keyLower) {
    try {
      // direct match (case-insensitive)
      for (final k in data.keys) {
        if (k.toString().toLowerCase() == keyLower) {
          return data[k];
        }
      }

      // substring match
      for (final k in data.keys) {
        final kl = k.toString().toLowerCase();
        if (kl.contains(keyLower)) {
          return data[k];
        }
      }

      // if values are maps, search recursively
      for (final k in data.keys) {
        final v = data[k];
        if (v is Map) {
          final found = _searchRecursive(v.cast<String, dynamic>(), keyLower);
          if (found != null) return found;
        }
      }
    } catch (_) {}
    return null;
  }

  // Try many common nested keys inside a map (e.g. { probability: 0.85 }, { value: 32.5 }, { score: 32 })
  dynamic _extractFromNestedMap(Map m) {
    final candidates = [
      "value",
      "score",
      "probability",
      "prob",
      "percentage",
      "pct",
      "count",
      "current",
      "streak",
      "days",
      "level",
      "prediction",
      "insight",
      "peakTime",
      "peak",
      "topTrigger",
      "top_trigger",
    ];
    for (final c in candidates) {
      if (m.containsKey(c)) return m[c];
      // case-insensitive
      for (final k in m.keys) {
        if (k.toString().toLowerCase() == c.toLowerCase()) return m[k];
      }
    }
    // try recursively deeper
    for (final k in m.keys) {
      final v = m[k];
      if (v is Map) {
        final nested = _extractFromNestedMap(v.cast<String, dynamic>());
        if (nested != null) return nested;
      }
    }
    return null;
  }

  // Raw lookup that tries direct, substring and nested search
  dynamic _rawLookup(Map<String, dynamic>? data, String key) {
    if (data == null) return null;

    try {
      final keyLower = key.toLowerCase();

      // direct exact match (case-insensitive)
      for (final k in data.keys) {
        if (k.toString().toLowerCase() == keyLower) return data[k];
      }

      // exact common synonyms — quick map
      final synonyms = <String, String>{
        "relapseprobability": "relapseProbability",
        "recoveryscore": "recoveryScore",
        "currentstreak": "currentStreak",
        "urgeheatmap": "urgeHeatmap",
        "sevendayurgetrend": "sevenDayUrgeTrend",
      };
      if (synonyms.containsKey(keyLower) &&
          data.containsKey(synonyms[keyLower]!)) {
        return data[synonyms[keyLower]!]!;
      }

      // substring match across keys
      final foundSubstring = _searchRecursive(data, keyLower);
      if (foundSubstring != null) return foundSubstring;

      // if not found, try to find likely nested object that might contain the value
      for (final k in data.keys) {
        final v = data[k];
        if (v is Map) {
          // search nested by similar key
          final nestedVal = _searchRecursive(
            v.cast<String, dynamic>(),
            keyLower,
          );
          if (nestedVal != null) return nestedVal;
          // or try extract common field from nested map
          final extracted = _extractFromNestedMap(v.cast<String, dynamic>());
          if (extracted != null) return extracted;
        }
      }
    } catch (_) {}
    return null;
  }

  String _safeString(
    Map<String, dynamic> data,
    String key, {
    String fallback = "unknown",
  }) {
    try {
      final raw = _rawLookup(data, key);
      if (raw == null) return fallback;
      if (raw is String) {
        final s = raw.trim();
        if (s.isEmpty) return fallback;
        return s;
      }
      // if nested map/other -> try extracting a nested textual representation
      if (raw is Map) {
        // try common text keys
        for (final t in [
          "label",
          "name",
          "insight",
          "summary",
          "description",
          "topTrigger",
        ]) {
          if (raw.containsKey(t)) {
            final v = raw[t];
            if (v != null) return v.toString();
          }
        }
        // fallback to toString
        return raw.toString();
      }
      return raw.toString();
    } catch (_) {
      return fallback;
    }
  }

  String _safeNumber(
    Map<String, dynamic> data,
    String key, {
    String fallback = "unknown",
  }) {
    try {
      final raw = _rawLookup(data, key);
      if (raw == null) return fallback;

      // numeric value
      if (raw is num) {
        if ((raw % 1) == 0) return raw.toInt().toString();
        return raw.toString();
      }

      // sometimes services return nested maps
      if (raw is Map) {
        final extracted = _extractFromNestedMap(raw.cast<String, dynamic>());
        if (extracted != null) {
          return _safeNumber({"v": extracted}, "v", fallback: fallback);
        }
        return fallback;
      }

      // string value possibly with percent or numeric
      if (raw is String) {
        final s = raw.trim();
        // remove percent sign if present and parse
        final cleaned = s.replaceAll("%", "");
        final parsed = double.tryParse(cleaned);
        if (parsed != null) {
          // if originally had %, do not append it here (this is number getter)
          if ((parsed % 1) == 0) return parsed.toInt().toString();
          return parsed.toString();
        }
        // maybe it's like "32 / 100" — extract first number
        final match = RegExp(r"(\d+(\.\d+)?)").firstMatch(s);
        if (match != null) {
          final numStr = match.group(0)!;
          final p = double.tryParse(numStr);
          if (p != null) {
            return p % 1 == 0 ? p.toInt().toString() : p.toString();
          }
        }
        // otherwise fallback to original string
        return s;
      }

      // any other type -> toString
      return raw.toString();
    } catch (_) {
      return fallback;
    }
  }

  String _safePercent(
    Map<String, dynamic> data,
    String key, {
    String fallback = "unknown",
  }) {
    try {
      final raw = _rawLookup(data, key);
      if (raw == null) return fallback;

      // if numeric
      if (raw is num) {
        // if fractional 0..1 convert to percent
        if (raw >= 0 && raw <= 1) {
          final pct = raw * 100;
          if ((pct % 1) == 0) return "${pct.toInt()}%";
          return "${pct.toStringAsFixed(1)}%";
        } else {
          // if in 0..100 range
          if ((raw % 1) == 0) return "${raw.toInt()}%";
          return "${raw.toStringAsFixed(1)}%";
        }
      }

      // if map, try nested extraction
      if (raw is Map) {
        final extracted = _extractFromNestedMap(raw.cast<String, dynamic>());
        if (extracted != null)
          return _safePercent({"v": extracted}, "v", fallback: fallback);
        return fallback;
      }

      // string
      if (raw is String) {
        final s = raw.trim();
        if (s.endsWith("%")) return s;
        final parsed = double.tryParse(s.replaceAll("%", ""));
        if (parsed != null) {
          if (parsed >= 0 && parsed <= 1) {
            final pct = parsed * 100;
            return (pct % 1) == 0
                ? "${pct.toInt()}%"
                : "${pct.toStringAsFixed(1)}%";
          } else {
            return (parsed % 1) == 0
                ? "${parsed.toInt()}%"
                : "${parsed.toStringAsFixed(1)}%";
          }
        }
        // fallback return original string
        return s;
      }

      return raw.toString();
    } catch (_) {
      return fallback;
    }
  }

  String _safeOneLine(
    Map<String, dynamic> data,
    String key, {
    String fallback = "unknown",
  }) {
    final s = _safeString(data, key, fallback: fallback);
    return s.replaceAll(RegExp(r"\s+"), " ").trim();
  }

  // ---------------------------------------------------------------------------------------
  // the rest of the file (generateResponse and all handlers) remain unchanged below
  // ---------------------------------------------------------------------------------------

  Future<String> generateResponse({
    required String userMessage,
    required Map<String, dynamic> context,
  }) async {
    final message = userMessage.toLowerCase();

    _memoryService.addUserMessage(message);

    final history = _memoryService.getHistory();

    /// --------------------------------------------------
    /// COLLECT ALL ENGINE DATA
    /// --------------------------------------------------
    Map<String, dynamic> engineData = await _engineContext.collectEngineData();

    /// --------------------------------------------------
    /// ENGINE EXPLANATION + USER DATA
    /// (each section explains the engine and prints user's current data)
    /// --------------------------------------------------

    // Recovery Score
    if (message.contains("recovery score")) {
      final score = _safeNumber(
        engineData,
        "recoveryScore",
        fallback: "unknown",
      );
      final level = _safeString(
        engineData,
        "recoveryLevel",
        fallback: "unknown",
      );

      final reply =
          """
Recovery Score

What it is:
Recovery Score measures the overall stability of your recovery journey.

How it's computed:
• behavioral stability
• urge trends and intensity
• emotional balance
• habit consistency
• relapse risk signals

Your Current Recovery Score:
$score / 100

Recovery Level:
$level

Tip:
If your score is low, focus on small consistent actions today (avoid triggers, complete one recovery activity, and follow AI guidance).
""";

      _memoryService.addAIMessage(reply);
      return reply;
    }

    /// --------------------------------------------------
/// RELAPSE RISK ANALYSIS
/// --------------------------------------------------

if (message.contains("relapse probability") ||
    message.contains("relapse risk")) {

  final probabilityValue = engineData["relapseProbability"];
  final probability = probabilityValue != null
      ? "${probabilityValue.toString()}%"
      : "Unknown";

  final level = engineData["relapseLevel"]?.toString() ?? "Unknown";

  final reply =
      """
Relapse Risk Analysis

Probability:
$probability

Risk Level:
$level

Explanation:
This value represents the probability of relapse calculated by
the relapse prediction engine.

Action:
If this value is high, strengthen your recovery defenses by avoiding triggers,
following AI guidance, and contacting your support system if necessary.
""";

  _memoryService.addAIMessage(reply);
  return reply;
}

  // Urge Prediction
    if (message.contains("urge prediction") ||
        message.contains("urge predictor")) {
      final urge = _safeOneLine(
        engineData,
        "urgePrediction",
        fallback: "unknown",
      );
      final window = _safeOneLine(
        engineData,
        "urgePredictionWindow",
        fallback: "next 1 hour",
      );
      final probability = _safeNumber(
        engineData,
        "urgePredictionProbability",
        fallback: "unknown",
      );

      final reply =
          """
Urge Prediction Engine

What it is:
This engine forecasts when urges are most likely to occur by analyzing your past behavior,
triggers, emotional states, and recent activity.

Current Prediction:
$urge

Prediction Window:
$window

Probability:
$probability%

Tip:
When prediction is high, use short, actionable coping techniques (breathing, change environment, notify guardian).
""";

      _memoryService.addAIMessage(reply);
      return reply;
    }

    // 7-Day Urge Trend
    if (message.contains("7 day urge") ||
        message.contains("7-day urge") ||
        message.contains("urge trend")) {
      final trend = _safeOneLine(
        engineData,
        "sevenDayUrgeTrend",
        fallback: "unknown",
      );
      final reply =
          """
7-Day Urge Trend

What it is:
Tracks how your urges are changing over the last 7 days to identify rising or falling trends.

Current 7-Day Trend:
$trend

Why it matters:
An increasing trend signals you should use prevention techniques and review triggers for the last week.

Tip:
If trend is rising, try scheduling one healthy habit in the time windows you usually experience urges.
""";

      _memoryService.addAIMessage(reply);
      return reply;
    }

    // Urge Heatmap (hourly)
    if (message.contains("urge heatmap") ||
        message.contains("heatmap") ||
        message.contains("hourly")) {
      final heatmap = _safeOneLine(
        engineData,
        "urgeHeatmap",
        fallback: "unknown",
      );
      final reply =
          """
Urge Heatmap (Hourly)

What it is:
An hourly heatmap showing which times of day you most frequently report urges.

Peak times / pattern:
$heatmap

Why it helps:
Knowing the peak hours lets you plan to be away from triggers or schedule supportive activities during that time.

Tip:
If you see an evening peak, plan structured evening activities or set a 'non-phone' period.
""";

      _memoryService.addAIMessage(reply);
      return reply;
    }

    // Emotion Distribution
    if (message.contains("emotion distribution") ||
        message.contains("emotional distribution") ||
        message.contains("emotion trends")) {
      final emotions = _safeOneLine(
        engineData,
        "emotionDistribution",
        fallback: "unknown",
      );

      final reply =
          """
Emotion Distribution

What it is:
Shows the balance of emotional states (e.g., sad, anxious, calm) across a period.

Current Emotional Pattern:
$emotions

Why it helps:
Emotional patterns often precede urges; spotting them early can trigger coping actions.

Tip:
If negative emotions are frequent, use grounding techniques and reach out to a support contact.
""";

      _memoryService.addAIMessage(reply);
      return reply;
    }

    // Habit Loop Insight
    if (message.contains("habit loop") ||
        message.contains("habit loop insight")) {
      final habit = _safeOneLine(
        engineData,
        "habitLoopInsight",
        fallback: "unknown",
      );
      final frequency = _safeNumber(
        engineData,
        "habitLoopFrequency",
        fallback: "unknown",
      );

      final reply =
          """
Habit Loop Insight

What it is:
Identifies repeating cycles of Trigger → Behavior → Reward that keep a habit running.

Detected insight:
$habit

Frequency:
$frequency times (approx.)

Why it matters:
Understanding the loop helps you change the reward or avoid the trigger.

Suggested step:
Replace the reward with a healthier alternative or interrupt the loop at the trigger stage.
""";

      _memoryService.addAIMessage(reply);
      return reply;
    }

    // Trigger Mapping
    if (message.contains("trigger mapping") || message.contains("trigger")) {
      final trigger = _safeOneLine(
        engineData,
        "triggerMapping",
        fallback: "unknown",
      );
      final topTriggerConfidence = _safeString(
        engineData,
        "triggerTopConfidence",
        fallback: "unknown",
      );

      final reply =
          """
Trigger Mapping

What it is:
Detects specific situations, places, people, or emotions that increase urge probability.

Top detected trigger:
$trigger

Confidence / additional info:
$topTriggerConfidence

Action:
Avoid or restructure the context of that trigger where possible, or prepare a coping strategy when exposure can't be avoided.
""";

      _memoryService.addAIMessage(reply);
      return reply;
    }

    // Behavioral Stability
    if (message.contains("behavioral stability") ||
        message.contains("behavioural stability")) {
      final stability = _safeNumber(
        engineData,
        "behavioralStability",
        fallback: "unknown",
      );
      final level = _safeOneLine(
        engineData,
        "behavioralStabilityLevel",
        fallback: "unknown",
      );

      final reply =
          """
Behavioral Stability

What it is:
Measures how consistent your recovery behaviors are over time (higher = more stable).

Current Stability:
$stability

Stability level:
$level

Meaning:
Higher stability suggests stronger habit formation and lower relapse risk.

Tip:
To improve stability, keep consistent daily routines and complete simple recovery tasks every day.
""";

      _memoryService.addAIMessage(reply);
      return reply;
    }

    // Behavioral Pattern Insight
    if (message.contains("behavioral pattern") ||
        message.contains("behavior pattern insight") ||
        message.contains("behavior insight")) {
      final pattern = _safeOneLine(
        engineData,
        "behavioralInsight",
        fallback: "unknown",
      );
      final confidence = _safeString(
        engineData,
        "behavioralPatternConfidence",
        fallback: "unknown",
      );

      final reply =
          """
Behavioral Pattern Insight

What it is:
Analyzes long-term trends to identify recurring behavior clusters that relate to urges or progress.

Detected pattern:
$pattern

Confidence:
$confidence

Why it helps:
Gives targeted suggestions (e.g., avoid certain situations during high-risk windows).

Action:
Follow the tailored suggestions and monitor how the pattern changes over the next week.
""";

      _memoryService.addAIMessage(reply);
      return reply;
    }

    // Pre-Relapse Warning
    if (message.contains("pre relapse") ||
        message.contains("pre-relapse") ||
        message.contains("pre relapse warning")) {
      final warning = _safeOneLine(
        engineData,
        "preRelapseWarning",
        fallback: "inactive",
      );
      final explanation = _safeOneLine(
        engineData,
        "preRelapseExplanation",
        fallback: "No immediate pre-relapse signals detected.",
      );

      final reply =
          """
Pre-Relapse Warning

What it is:
A short-horizon warning that triggers when patterns closely match those seen directly before previous relapses.

Status:
$warning

Details:
$explanation

Action:
If active, please follow immediate prevention steps: pause, contact a trusted person, or follow the emergency reset flow in the app.
""";

      _memoryService.addAIMessage(reply);
      return reply;
    }

    // Guardian Mode
    if (message.contains("guardian mode") || message.contains("guardian")) {
      final guardian = _safeOneLine(
        engineData,
        "guardianMode",
        fallback: "inactive",
      );

      final reply =
          """
Guardian Mode

What it is:
A safety feature that can alert a trusted contact or limit risky features when relapse risk is high.

Status:
$guardian

Recommended use:
If Guardian Mode is inactive but your relapse risk is elevated, consider enabling it or notifying a trusted contact now.
""";

      _memoryService.addAIMessage(reply);
      return reply;
    }

    // AI Daily Guidance
    if (message.contains("guidance") ||
        message.contains("ai daily") ||
        message.contains("daily guidance")) {
      final guidance = _safeString(
        engineData,
        "aiGuidance",
        fallback: "Stay focused on your recovery today.",
      );

      final reply =
          """
AI Daily Guidance

What it is:
Personalized daily suggestions based on your current risk, recent activity, and engine signals.

Today's guidance:
$guidance

Tip:
Use this guidance as a short checklist for the day — one small action now can reduce risk later.
""";

      _memoryService.addAIMessage(reply);
      return reply;
    }

    /// --------------------------------------------------
    /// CURRENT STREAK
    /// --------------------------------------------------

    if (message.contains("streak")) {
      final current = _safeNumber(engineData, "currentStreak", fallback: "0");
      final best = _safeNumber(engineData, "bestStreak", fallback: "0");

      final reply =
          """
Recovery Streak

Current Streak:
$current days

Best Streak:
$best days

Tip:
Consistency is the strongest predictor of long-term recovery success.
Focus on protecting today's progress.
""";

      _memoryService.addAIMessage(reply);
      return reply;
    }

    /// --------------------------------------------------
    /// CURRENT RISK
    /// --------------------------------------------------

    if (message.contains("current risk") || message.contains("risk level")) {
  final level = engineData["currentRisk"]?.toString() ?? "Unknown";

  final probabilityValue = engineData["currentRiskProbability"];
  final probability = probabilityValue != null
      ? "${probabilityValue.toStringAsFixed(1)}%"
      : "Unknown";

      final reply =
          """
Current Risk

Risk Level:
$level

Risk Probability:
$probability

Explanation:
Risk level is calculated using behavioral signals, urge patterns,
and emotional stability indicators.
""";

      _memoryService.addAIMessage(reply);
      return reply;
    }

    /// ----------------------------------
    /// 1️⃣ CRISIS DETECTION
    /// ----------------------------------

    if (AICrisisRouter.isCrisis(message)) {
      final reply = _randomResponse(crisisResponses);

      _memoryService.addAIMessage(reply);

      return reply;
    }

    /// ----------------------------------
    /// 2️⃣ EMOTION DETECTION
    /// ----------------------------------

    if (AIEmotionRouter.isAppreciation(message)) {
      final reply = _randomResponse(appreciationResponses);
      _memoryService.addAIMessage(reply);
      return reply;
    }

    if (AIEmotionRouter.isFrustrated(message)) {
      final reply = _randomResponse(frustrationResponses);
      _memoryService.addAIMessage(reply);
      return reply;
    }

    if (AIEmotionRouter.isSad(message)) {
      final reply = _randomResponse(sadnessResponses);
      _memoryService.addAIMessage(reply);
      return reply;
    }

    if (AIEmotionRouter.isAnxious(message)) {
      final reply = _randomResponse(anxietyResponses);
      _memoryService.addAIMessage(reply);
      return reply;
    }

    if (AIEmotionRouter.isHappy(message)) {
      final reply = _randomResponse(happinessResponses);
      _memoryService.addAIMessage(reply);
      return reply;
    }

    /// --------------------------------------------------
    /// 3️⃣ ENGINE DATA QUICK QUERIES (AIDataRouter)
    /// --------------------------------------------------

    if (AIDataRouter.asksRecoveryScore(message)) {
      final reply =
          """
Recovery Score: ${_safeNumber(engineData, "recoveryScore", fallback: "unknown")}/100

Recovery Score reflects how stable your recovery progress is.  
It combines behavioral stability, emotional balance, urge patterns, and habit consistency.
""";

      _memoryService.addAIMessage(reply);
      return reply;
    }

    if (AIDataRouter.asksRelapseRisk(message)) {
      final reply =
          """
Relapse Probability: ${_safePercent(engineData, "relapseProbability", fallback: "unknown")}

Relapse Risk Analysis evaluates behavioral signals, urge patterns, triggers,
and emotional instability to estimate relapse likelihood.
""";

      _memoryService.addAIMessage(reply);
      return reply;
    }

    if (AIDataRouter.asksUrgePrediction(message)) {
      final reply =
          """
Urge Prediction Level: ${_safeOneLine(engineData, "urgePrediction", fallback: "unknown")}

This engine analyzes emotional signals, behavior patterns, and trigger environments to estimate when urges may occur.
""";

      _memoryService.addAIMessage(reply);
      return reply;
    }

    if (AIDataRouter.asksCurrentStreak(message)) {
      final reply =
          """
Current Recovery Streak: ${_safeNumber(engineData, "currentStreak", fallback: "0")} days

Maintaining streaks strengthens positive behavioral patterns.
""";

      _memoryService.addAIMessage(reply);
      return reply;
    }

    /// --------------------------------------------------
    /// 4️⃣ FULL ENGINE DASHBOARD RESPONSE
    /// --------------------------------------------------

    bool isFeatureQuestion = featureKeywords.any((k) => message.contains(k));

    if (isFeatureQuestion) {
      final reply =
          """
Here are your latest ReWireX recovery insights:

Recovery Score: ${_safeNumber(engineData, "recoveryScore", fallback: "unknown")}/100

Relapse Probability: ${_safePercent(engineData, "relapseProbability")}
Relapse Level: ${_safeString(engineData, "relapseLevel")}

Current Risk: ${_safeString(engineData, "currentRisk")}
Risk Probability: ${_safePercent(engineData, "currentRiskProbability")}

Current Streak: ${_safeNumber(engineData, "currentStreak")} days
Best Streak: ${_safeNumber(engineData, "bestStreak")} days

Urge Prediction: ${_safeOneLine(engineData, "urgePrediction", fallback: "unknown")}
7-Day Urge Trend: ${_safeOneLine(engineData, "sevenDayUrgeTrend", fallback: "unknown")}
Urge Heatmap (Hourly): ${_safeOneLine(engineData, "urgeHeatmap", fallback: "unknown")}

Emotion Distribution: ${_safeOneLine(engineData, "emotionDistribution", fallback: "unknown")}

Trigger Mapping: ${_safeOneLine(engineData, "triggerMapping", fallback: "unknown")}
Habit Loop Insight: ${_safeOneLine(engineData, "habitLoopInsight", fallback: "unknown")}

Behavioral Stability: ${_safeNumber(engineData, "behavioralStability", fallback: "unknown")}
Behavioral Pattern Insight: ${_safeOneLine(engineData, "behavioralInsight", fallback: "unknown")}

Pre-Relapse Warning: ${_safeOneLine(engineData, "preRelapseWarning", fallback: "inactive")}

Guardian Mode: ${_safeOneLine(engineData, "guardianMode", fallback: "inactive")}

AI Daily Guidance:
${_safeOneLine(engineData, "aiGuidance", fallback: "Stay focused on your recovery today.")}
""";

      _memoryService.addAIMessage(reply);
      return reply;
    }

    /// --------------------------------------------------
    /// 5️⃣ RECOVERY QUESTIONS (local engine then llm)
    /// --------------------------------------------------

    if (AIIntentRouter.isRecoveryQuery(message)) {
      final localResponse = _localEngine.generateLocalResponse(message);

      if (localResponse.isNotEmpty) {
        _memoryService.addAIMessage(localResponse);
        return localResponse;
      }

      final llmResponse = await _llmService.generateResponse(message, history);

      if (llmResponse != null && llmResponse.isNotEmpty) {
        _memoryService.addAIMessage(llmResponse);
        return llmResponse;
      }
    }

    /// --------------------------------------------------
    /// 6️⃣ MOOD QUESTIONS (LLM)
    /// --------------------------------------------------

    if (AIIntentRouter.isMoodQuery(message)) {
      final llmResponse = await _llmService.generateResponse(message, history);

      if (llmResponse != null && llmResponse.isNotEmpty) {
        _memoryService.addAIMessage(llmResponse);
        return llmResponse;
      }
    }

    /// --------------------------------------------------
    /// 7️⃣ APP QUESTIONS (LLM)
    /// --------------------------------------------------

    if (AIIntentRouter.isAppQuery(message)) {
      final llmResponse = await _llmService.generateResponse(message, history);

      if (llmResponse != null && llmResponse.isNotEmpty) {
        _memoryService.addAIMessage(llmResponse);
        return llmResponse;
      }
    }

    /// --------------------------------------------------
    /// FINAL API ATTEMPT (LLM)
    /// --------------------------------------------------

    final llmResponse = await _llmService.generateResponse(message, history);

    if (llmResponse != null && llmResponse.isNotEmpty) {
      _memoryService.addAIMessage(llmResponse);
      return llmResponse;
    }

    /// --------------------------------------------------
    /// FALLBACK
    /// --------------------------------------------------

    const fallback =
        "I'm the ReWireX AI recovery coach. I help with addiction recovery, managing urges, emotional support, and explaining how the ReWireX recovery system works.";

    _memoryService.addAIMessage(fallback);

    return fallback;
  }
}
