class AIEmotionRouter {

  /// -----------------------------
  /// Appreciation / Gratitude
  /// -----------------------------
  static const appreciation = [

    "thanks","thank you","thanks a lot","thank you so much","thx",
    "ty","tysm","appreciate it","i appreciate this","great help",
    "very helpful","that helped","this helped","thanks for helping",
    "good job","well done","great work","awesome","nice","good",
    "amazing help","wonderful","perfect","great support",

    "thanks buddy","thanks coach","thanks ai","thank you coach",
    "thank you ai","really appreciate it","i appreciate your help",

    "you helped me","that was useful","that was helpful",
    "that worked","it helped","i feel better now",

    "thank you for your support","thanks for your support",
    "thanks for the advice","thank you for the advice",

    "much appreciated","really appreciated","i am grateful",

  ];

  /// -----------------------------
  /// Frustration / Struggle
  /// -----------------------------
  static const frustration = [

    "i can't stop","i cant stop","i keep failing","i relapsed",
    "i failed","this is hard","this is difficult","i am stuck",
    "nothing works","i feel trapped","i hate this","i give up",

    "why is this happening","why am i like this","i feel weak",
    "i keep doing it","i always fail","i can't control myself",

    "i feel frustrated","this is frustrating","so frustrating",
    "i am angry","i am annoyed","i am irritated",

    "i hate myself","i hate this habit","i hate addiction",

    "i feel powerless","i feel helpless","i can't control urges",

    "i keep relapsing","i relapsed again","i slipped again",

    "i feel broken","this is impossible","i feel hopeless",

  ];

  /// -----------------------------
  /// Sadness / Depression
  /// -----------------------------
  static const sadness = [

    "i feel sad","i am sad","feeling sad","very sad",
    "i feel depressed","i am depressed","depression",
    "i feel down","feeling down",

    "i feel lonely","i am lonely","loneliness",

    "i feel empty","feeling empty","i feel numb",

    "i feel worthless","i feel useless",

    "i feel hopeless","hopeless","no hope",

    "i feel tired of life","i am tired of everything",

    "life is meaningless","nothing matters",

    "i feel alone","i feel abandoned",

    "i feel like crying","i want to cry",

  ];

  /// -----------------------------
  /// Anxiety / Stress
  /// -----------------------------
  static const anxiety = [

    "i feel anxious","i am anxious","anxiety",
    "i feel nervous","i am nervous",

    "i feel stressed","i am stressed","stress",

    "i feel overwhelmed","overwhelmed",

    "i feel panic","panic attack",

    "i feel worried","i am worried",

    "i overthink","overthinking","too many thoughts",

    "my mind won't stop","i can't relax",

  ];

  /// -----------------------------
  /// Happiness / Progress
  /// -----------------------------
  static const happiness = [

    "i feel happy","i am happy","feeling great",
    "i feel good","i feel better","i feel amazing",

    "i am improving","i made progress","i feel stronger",

    "i controlled my urge","i resisted the urge",

    "i didn't relapse","i stayed clean",

    "i feel proud","i am proud of myself",

    "today was good","i had a good day",

    "things are getting better","recovery is working",

  ];

  /// -----------------------------
  /// Detection functions
  /// -----------------------------

  static bool isAppreciation(String text) {
    return appreciation.any((k) => text.contains(k));
  }

  static bool isFrustrated(String text) {
    return frustration.any((k) => text.contains(k));
  }

  static bool isSad(String text) {
    return sadness.any((k) => text.contains(k));
  }

  static bool isAnxious(String text) {
    return anxiety.any((k) => text.contains(k));
  }

  static bool isHappy(String text) {
    return happiness.any((k) => text.contains(k));
  }

}