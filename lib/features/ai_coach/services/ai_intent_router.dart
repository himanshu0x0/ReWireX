class AIIntentRouter {

  /// -----------------------------
  /// RECOVERY / ADDICTION KEYWORDS
  /// -----------------------------
  static const recoveryKeywords = [

    "urge","urges","craving","cravings","relapse","addiction","addicted",
    "trigger","triggers","temptation","habit","habits","bad habit",
    "dopamine","dopamine addiction","dopamine detox","self control",
    "self-control","discipline","recovery","recovery journey",

    "porn","porn addiction","pornography","masturbation","fap","nofap",
    "sexual urges","lust","sexual temptation",

    "compulsion","compulsive behavior","impulse","impulse control",
    "loss of control","urge control",

    "how to stop","how to quit","how to recover","how to control urges",
    "why do urges happen","why relapse happens",

    "late night urges","night urges","bedtime urges",
    "internet addiction","phone addiction","social media addiction",

    "withdrawal","withdrawal symptoms",
    "recovery progress","recovery plan","recovery strategy",

    "slip","slipped","i relapsed","i failed","i watched porn",
    "i can't stop","i feel addicted",

    "motivation","stay strong","help me quit","help me stop",

    "urge management","trigger management",
    "addiction recovery","behavior change",
  ];

  /// -----------------------------
  /// MOOD / EMOTIONAL STATES
  /// -----------------------------
  static const moodKeywords = [

    "sad","sadness","depressed","depression","lonely","loneliness",
    "anxious","anxiety","panic","stress","stressed","overwhelmed",

    "angry","anger","frustrated","frustration","irritated",
    "guilt","guilty","shame","ashamed",

    "hopeless","helpless","worthless","empty","burnout",

    "bored","boredom","tired","fatigue","mental fatigue",

    "i feel sad","i feel lonely","i feel anxious",
    "i feel depressed","i feel stressed",

    "low mood","bad mood","negative thoughts",

    "emotions","emotional pain","emotional struggle",

    "motivation loss","lack of motivation",
    "demotivated","unmotivated",

    "mental health","mental struggle","mental state",

    "self doubt","overthinking","rumination",

    "feeling weak","feeling lost","feeling stuck"
  ];

  /// -----------------------------
  /// APP / REWIREX SYSTEM QUESTIONS
  /// -----------------------------
  static const appKeywords = [

    "rewirex","this app","the app",

    "feature","features","app features",
    "benefits","advantages","why use this app",

    "how to use","how does this app work",
    "how does rewirex work",

    "guide","tutorial","instructions",
    "how to start","how to begin",

    "recovery tracker","urge tracker",
    "mood tracker","habit tracker",

    "guardian mode","guardian protection",
    "ai coach","ai recovery coach",

    "behavioral engine","recovery engine",
    "prediction engine","risk prediction",

    "relapse prediction","risk analysis",
    "recovery score","progress tracking",

    "dashboard","analytics","progress stats",

    "account","profile","settings",

    "data privacy","security","user data",

    "how to track urges",
    "how to track mood",
    "how to track habits",

    "notifications","reminders",

    "ai guidance","ai support",

    "recovery tools","self help tools",

    "what does this app do",
    "tell me about this app",
    "explain this app",

    "how can this app help me",
    "why should i use rewirex",

    "app purpose","app mission"
  ];

  /// -----------------------------
  /// DETECTION METHODS
  /// -----------------------------

  static bool isRecoveryQuery(String text) {
    final lower = text.toLowerCase();
    return recoveryKeywords.any((k) => lower.contains(k));
  }

  static bool isMoodQuery(String text) {
    final lower = text.toLowerCase();
    return moodKeywords.any((k) => lower.contains(k));
  }

  static bool isAppQuery(String text) {
    final lower = text.toLowerCase();
    return appKeywords.any((k) => lower.contains(k));
  }

}