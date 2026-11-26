import '../../../../ai/ai_service.dart';
import '../../domain/repositories/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  AiRepositoryImpl(this._service);

  final AiService _service;
  final Map<String, String> _answers = {};
  static const _maxCachedAnswers = 30;

  @override
  @override
  Future<void> saveApiKey(String key) async {
    try {
      await _service.saveApiKey(key);
    } on AiServiceException catch (error) {
      throw AiRepositoryException(error.message);
    }
  }

  @override
  @override
  String? cachedAnswer(String question) => _answers[_cacheKey(question)];

  @override
  Stream<String> ask(String question) async* {
    final key = _cacheKey(question);
    final cached = _answers[key];
    if (cached != null) {
      yield cached;
      return;
    }

    final answer = StringBuffer();
    try {
      await for (final chunk in _service.askStream(question)) {
        answer.write(chunk);
        yield chunk;
      }
    } on AiServiceException catch (error) {
      throw AiRepositoryException(error.message);
    }

    final text = answer.toString().trim();
    if (text.isNotEmpty) {
      if (_answers.length >= _maxCachedAnswers) {
        _answers.remove(_answers.keys.first);
      }
      _answers[key] = text;
    }
  }

  String _cacheKey(String question) =>
      question.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}
