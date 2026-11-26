abstract interface class AiRepository {
  Future<void> saveApiKey(String key);
  String? cachedAnswer(String question);

  Stream<String> ask(String question);
}

final class AiRepositoryException implements Exception {
  const AiRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
