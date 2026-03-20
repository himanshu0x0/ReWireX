class AIChatMessageModel {

  final String message;
  final bool isUser;
  final DateTime timestamp;

  AIChatMessageModel({
    required this.message,
    required this.isUser,
    required this.timestamp,
  });
}