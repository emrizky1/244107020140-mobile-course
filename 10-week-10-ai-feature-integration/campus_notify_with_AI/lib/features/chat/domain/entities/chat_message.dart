enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.isStreaming = false,
  });

  final ChatRole role;
  final String text;
  final bool isStreaming;

  ChatMessage copyWith({String? text, bool? isStreaming}) => ChatMessage(
    role: role,
    text: text ?? this.text,
    isStreaming: isStreaming ?? this.isStreaming,
  );
}
