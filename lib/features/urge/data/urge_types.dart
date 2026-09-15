
/// Stable identifiers for urges captured by the ReWireX Urge Rescue system.
///
/// IMPORTANT:
/// - [key] is persisted to Firestore / analytics and should NOT be changed
///   after release.
/// - UI text can change without affecting stored data.
/// - These represent the user's ACTION IMPULSE, not their emotion.
///
/// Example:
///   Emotion = anger
///   Trigger = conflict
///   Urge = sendAngryMessage
///   Need = beHeard
///   Rescue = Message Shield
enum UrgeType {
  sendAngryMessage,
  confront,
  retaliate,
  relapse,
  isolate,
  doomscroll,
  overthink,
  escape,
  shutDown,
  breakSomething,
  seekReassurance,
  giveUp,
  unknown,
}

enum UrgeRescuePath {
  messageShield,
  distanceAndRelease,
  recoveryRescue,
  connectionRescue,
  environmentReset,
  thoughtReset,
  activationRescue,
  basicGrounding,
}

extension UrgeTypeX on UrgeType {
  String get key {
    switch (this) {
      case UrgeType.sendAngryMessage:
        return 'send_angry_message';
      case UrgeType.confront:
        return 'confront';
      case UrgeType.retaliate:
        return 'retaliate';
      case UrgeType.relapse:
        return 'relapse';
      case UrgeType.isolate:
        return 'isolate';
      case UrgeType.doomscroll:
        return 'doomscroll';
      case UrgeType.overthink:
        return 'overthink';
      case UrgeType.escape:
        return 'escape';
      case UrgeType.shutDown:
        return 'shut_down';
      case UrgeType.breakSomething:
        return 'break_something';
      case UrgeType.seekReassurance:
        return 'seek_reassurance';
      case UrgeType.giveUp:
        return 'give_up';
      case UrgeType.unknown:
        return 'unknown';
    }
  }

  String get title {
    switch (this) {
      case UrgeType.sendAngryMessage:
        return 'Send an angry message';
      case UrgeType.confront:
        return 'Confront someone';
      case UrgeType.retaliate:
        return 'Retaliate';
      case UrgeType.relapse:
        return 'Relapse';
      case UrgeType.isolate:
        return 'Isolate myself';
      case UrgeType.doomscroll:
        return 'Doomscroll';
      case UrgeType.overthink:
        return 'Overthink';
      case UrgeType.escape:
        return 'Escape';
      case UrgeType.shutDown:
        return 'Shut down';
      case UrgeType.breakSomething:
        return 'Break something';
      case UrgeType.seekReassurance:
        return 'Seek reassurance';
      case UrgeType.giveUp:
        return 'Give up';
      case UrgeType.unknown:
        return 'Unclear urge';
    }
  }

  String get subtitle {
    switch (this) {
      case UrgeType.sendAngryMessage:
        return 'You feel pulled to message someone while angry.';
      case UrgeType.confront:
        return 'You feel pulled to confront someone right now.';
      case UrgeType.retaliate:
        return 'You feel pulled to get even or react back.';
      case UrgeType.relapse:
        return 'You feel pulled toward a behavior you are trying to change.';
      case UrgeType.isolate:
        return 'You feel pulled to withdraw from everyone.';
      case UrgeType.doomscroll:
        return 'You feel pulled to keep scrolling without a clear purpose.';
      case UrgeType.overthink:
        return 'You feel pulled into repeated thoughts and rumination.';
      case UrgeType.escape:
        return 'You feel pulled to avoid what is happening right now.';
      case UrgeType.shutDown:
        return 'You feel pulled to stop engaging and shut down.';
      case UrgeType.breakSomething:
        return 'You feel pulled toward destructive action.';
      case UrgeType.seekReassurance:
        return 'You feel pulled to repeatedly seek reassurance.';
      case UrgeType.giveUp:
        return 'You feel pulled to quit or stop trying.';
      case UrgeType.unknown:
        return 'You are experiencing a strong urge but cannot name it yet.';
    }
  }

  String get emoji {
    switch (this) {
      case UrgeType.sendAngryMessage:
        return '💬';
      case UrgeType.confront:
        return '🗣️';
      case UrgeType.retaliate:
        return '⚡';
      case UrgeType.relapse:
        return '🔄';
      case UrgeType.isolate:
        return '🚪';
      case UrgeType.doomscroll:
        return '📱';
      case UrgeType.overthink:
        return '🧠';
      case UrgeType.escape:
        return '🏃';
      case UrgeType.shutDown:
        return '🫥';
      case UrgeType.breakSomething:
        return '⚠️';
      case UrgeType.seekReassurance:
        return '🤝';
      case UrgeType.giveUp:
        return '🛑';
      case UrgeType.unknown:
        return '❔';
    }
  }

  UrgeRescuePath get defaultRescuePath {
    switch (this) {
      case UrgeType.sendAngryMessage:
        return UrgeRescuePath.messageShield;
      case UrgeType.confront:
      case UrgeType.retaliate:
      case UrgeType.breakSomething:
        return UrgeRescuePath.distanceAndRelease;
      case UrgeType.relapse:
        return UrgeRescuePath.recoveryRescue;
      case UrgeType.isolate:
      case UrgeType.seekReassurance:
      case UrgeType.giveUp:
        return UrgeRescuePath.connectionRescue;
      case UrgeType.doomscroll:
      case UrgeType.escape:
        return UrgeRescuePath.environmentReset;
      case UrgeType.overthink:
        return UrgeRescuePath.thoughtReset;
      case UrgeType.shutDown:
        return UrgeRescuePath.activationRescue;
      case UrgeType.unknown:
        return UrgeRescuePath.basicGrounding;
    }
  }

  bool get requiresSafetyReview {
    return this == UrgeType.breakSomething ||
        this == UrgeType.giveUp;
  }

  static UrgeType fromKey(String? value) {
    switch (value) {
      case 'send_angry_message':
        return UrgeType.sendAngryMessage;
      case 'confront':
        return UrgeType.confront;
      case 'retaliate':
        return UrgeType.retaliate;
      case 'relapse':
        return UrgeType.relapse;
      case 'isolate':
        return UrgeType.isolate;
      case 'doomscroll':
        return UrgeType.doomscroll;
      case 'overthink':
        return UrgeType.overthink;
      case 'escape':
        return UrgeType.escape;
      case 'shut_down':
        return UrgeType.shutDown;
      case 'break_something':
        return UrgeType.breakSomething;
      case 'seek_reassurance':
        return UrgeType.seekReassurance;
      case 'give_up':
        return UrgeType.giveUp;
      default:
        return UrgeType.unknown;
    }
  }
}

extension UrgeRescuePathX on UrgeRescuePath {
  String get key {
    switch (this) {
      case UrgeRescuePath.messageShield:
        return 'message_shield';
      case UrgeRescuePath.distanceAndRelease:
        return 'distance_and_release';
      case UrgeRescuePath.recoveryRescue:
        return 'recovery_rescue';
      case UrgeRescuePath.connectionRescue:
        return 'connection_rescue';
      case UrgeRescuePath.environmentReset:
        return 'environment_reset';
      case UrgeRescuePath.thoughtReset:
        return 'thought_reset';
      case UrgeRescuePath.activationRescue:
        return 'activation_rescue';
      case UrgeRescuePath.basicGrounding:
        return 'basic_grounding';
    }
  }

  String get title {
    switch (this) {
      case UrgeRescuePath.messageShield:
        return 'Message Shield';
      case UrgeRescuePath.distanceAndRelease:
        return 'Distance & Release';
      case UrgeRescuePath.recoveryRescue:
        return 'Recovery Rescue';
      case UrgeRescuePath.connectionRescue:
        return 'Connection Rescue';
      case UrgeRescuePath.environmentReset:
        return 'Environment Reset';
      case UrgeRescuePath.thoughtReset:
        return 'Thought Reset';
      case UrgeRescuePath.activationRescue:
        return 'Activation Rescue';
      case UrgeRescuePath.basicGrounding:
        return 'Basic Grounding';
    }
  }

  static UrgeRescuePath fromKey(String? value) {
    switch (value) {
      case 'message_shield':
        return UrgeRescuePath.messageShield;
      case 'distance_and_release':
        return UrgeRescuePath.distanceAndRelease;
      case 'recovery_rescue':
        return UrgeRescuePath.recoveryRescue;
      case 'connection_rescue':
        return UrgeRescuePath.connectionRescue;
      case 'environment_reset':
        return UrgeRescuePath.environmentReset;
      case 'thought_reset':
        return UrgeRescuePath.thoughtReset;
      case 'activation_rescue':
        return UrgeRescuePath.activationRescue;
      default:
        return UrgeRescuePath.basicGrounding;
    }
  }
}