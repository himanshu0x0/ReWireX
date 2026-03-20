class AICrisisRouter {

  static const crisisKeywords = [

    /// SUICIDAL IDEATION
    "i want to die",
    "i want to kill myself",
    "i feel suicidal",
    "suicide",
    "suicidal",
    "i am suicidal",
    "thinking about suicide",
    "i might kill myself",
    "i want to end my life",
    "i want my life to end",
    "i wish i was dead",
    "i should be dead",
    "i should just die",
    "i want to disappear forever",
    "i want to stop existing",
    "life is not worth living",
    "i don't want to live",
    "i don't want to live anymore",
    "i cannot live like this",
    "i want everything to stop",

    /// SELF HARM
    "i want to hurt myself",
    "i want to harm myself",
    "i feel like hurting myself",
    "self harm",
    "self-harm",
    "cut myself",
    "i want to cut myself",
    "i feel like cutting",
    "i want to injure myself",
    "i deserve pain",
    "i should punish myself",

    /// HOPELESSNESS
    "life is pointless",
    "life has no meaning",
    "there is no reason to live",
    "nothing matters anymore",
    "everything is meaningless",
    "i feel completely hopeless",
    "i have no hope",
    "there is no hope for me",
    "i feel empty inside",
    "i feel broken inside",
    "my life is over",

    /// EXTREME DESPAIR
    "i can't go on",
    "i can't continue",
    "i give up on life",
    "i am done with life",
    "i am tired of living",
    "i don't want to exist",
    "i wish i never existed",
    "i feel like disappearing",
    "i want to vanish",
    "i want to escape life",

    /// EXTREME LONELINESS
    "no one cares about me",
    "nobody cares about me",
    "everyone would be better without me",
    "people would be happier without me",
    "i am a burden to everyone",
    "i don't matter to anyone",
    "i feel completely alone",
    "no one understands me",

    /// EMOTIONAL COLLAPSE
    "i can't handle this anymore",
    "i feel like breaking down",
    "i feel like giving up",
    "i am mentally exhausted",
    "i can't deal with life",
    "everything is too much",
    "i feel overwhelmed with life",

    /// EXISTENTIAL DESPAIR
    "what's the point of living",
    "what is the point of life",
    "why should i live",
    "why am i alive",
    "why do i exist",
    "life has no purpose",

    /// EXTREME DEPRESSION
    "i feel completely worthless",
    "i feel useless",
    "i hate my life",
    "i hate being alive",
    "i feel like a failure",
    "i ruin everything",

    /// FINAL GOODBYE TYPE STATEMENTS
    "goodbye forever",
    "this is my last message",
    "i don't think i will be here tomorrow",
    "i won't be around anymore",
    "this is the end for me",

    /// RELAPSE + CRISIS MIX
    "i relapsed and want to die",
    "i relapsed again and feel hopeless",
    "i can't stop addiction and want to die",
    "my addiction ruined my life",
    "i feel destroyed by addiction",

    /// GENERAL SUICIDE REFERENCES
    "thinking about ending it all",
    "ending it all",
    "ending my life",
    "i might end my life",
    "i don't see a future",
    "i see no future for myself",

    /// DESPERATE HELP SIGNALS
    "i need serious help",
    "i am not safe right now",
    "i feel like i might hurt myself",
    "i feel like i might die",
    "i cannot survive this",

  ];

  static bool isCrisis(String text) {

    final lower = text.toLowerCase();

    return crisisKeywords.any((k) => lower.contains(k));

  }
}