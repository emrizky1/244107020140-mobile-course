import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/usecases/chat_sanitizer.dart';

final aiRepositoryProvider = Provider<AiRepository>(
  (ref) => throw StateError(
    'Override aiRepositoryProvider in the app composition root.',
  ),
);

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.lastQuestion,
    this.privacyWarning,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final String? lastQuestion;
  final String? privacyWarning;
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);

class ChatNotifier extends Notifier<ChatState> {
  static const cooldown = Duration(seconds: 2);
  DateTime? _lastRequestAt;

  @override
  ChatState build() => const ChatState();

  Future<void> send(String question) => _send(question);

  void dismissPrivacyWarning() {
    state = ChatState(
      messages: state.messages,
      isLoading: state.isLoading,
      error: state.error,
      lastQuestion: state.lastQuestion,
    );
  }

  Future<String?> saveApiKey(String key) async {
    try {
      await ref.read(aiRepositoryProvider).saveApiKey(key);
      state = ChatState(
        messages: state.messages,
        privacyWarning: state.privacyWarning,
      );
      return null;
    } on AiRepositoryException catch (error) {
      return error.message;
    } catch (_) {
      return 'API key gagal disimpan. Coba lagi.';
    }
  }

  Future<void> retry() async {
    final question = state.lastQuestion;
    if (question == null || state.isLoading) return;
    final messages = [...state.messages];
    if (messages.isEmpty || messages.last.role != ChatRole.user) {
      messages.add(ChatMessage(role: ChatRole.user, text: question));
    }
    state = ChatState(messages: messages, lastQuestion: question);
    await _send(question, addUserMessage: false, bypassCooldown: true);
  }

  Future<void> _send(
    String question, {
    bool addUserMessage = true,
    bool bypassCooldown = false,
  }) async {
    final sanitized = ChatSanitizer.sanitizeInput(question);
    final normalized = sanitized.text;
    if (normalized.isEmpty || state.isLoading) return;
    final privacyWarning = sanitized.containsSensitiveData
        ? 'Nomor identitas atau telepon terdeteksi dan disamarkan sebelum dikirim.'
        : null;

    final repository = ref.read(aiRepositoryProvider);
    final cached = repository.cachedAnswer(normalized);
    if (cached != null) {
      state = ChatState(
        messages: [
          ...state.messages,
          if (addUserMessage)
            ChatMessage(role: ChatRole.user, text: normalized),
          ChatMessage(role: ChatRole.assistant, text: cached),
        ],
        privacyWarning: privacyWarning,
      );
      return;
    }

    final now = DateTime.now();
    final lastRequestAt = _lastRequestAt;
    if (!bypassCooldown &&
        lastRequestAt != null &&
        now.difference(lastRequestAt) < cooldown) {
      state = ChatState(
        messages: [
          ...state.messages,
          if (addUserMessage)
            ChatMessage(role: ChatRole.user, text: normalized),
        ],
        error: 'Tunggu sebentar sebelum mengirim pertanyaan berikutnya.',
        lastQuestion: normalized,
        privacyWarning: privacyWarning,
      );
      return;
    }

    _lastRequestAt = now;
    final messages = [
      ...state.messages,
      if (addUserMessage) ChatMessage(role: ChatRole.user, text: normalized),
      const ChatMessage(role: ChatRole.assistant, text: '', isStreaming: true),
    ];
    state = ChatState(
      messages: messages,
      isLoading: true,
      lastQuestion: normalized,
      privacyWarning: privacyWarning,
    );

    final answer = StringBuffer();
    try {
      await for (final chunk in repository.ask(normalized)) {
        answer.write(chunk);
        final visibleText = ChatSanitizer.sanitizeResponse(answer.toString());
        final updated = [...state.messages];
        updated[updated.length - 1] = ChatMessage(
          role: ChatRole.assistant,
          text: visibleText,
          isStreaming: true,
        );
        state = ChatState(
          messages: updated,
          isLoading: true,
          lastQuestion: normalized,
          privacyWarning: privacyWarning,
        );
      }
      if (answer.toString().trim().isEmpty) {
        throw const AiRepositoryException('Jawaban AI kosong. Coba lagi.');
      }
      final completed = [...state.messages];
      completed[completed.length - 1] = ChatMessage(
        role: ChatRole.assistant,
        text: ChatSanitizer.sanitizeResponse(answer.toString()),
      );
      if (completed.last.text.isEmpty) {
        throw const AiRepositoryException('Jawaban AI kosong. Coba lagi.');
      }
      state = ChatState(messages: completed, privacyWarning: privacyWarning);
    } catch (error) {
      final failed = [...state.messages]..removeLast();
      state = ChatState(
        messages: failed,
        error: error is AiRepositoryException
            ? error.message
            : 'Jawaban gagal dimuat. Periksa koneksi lalu coba lagi.',
        lastQuestion: normalized,
        privacyWarning: privacyWarning,
      );
    }
  }
}
