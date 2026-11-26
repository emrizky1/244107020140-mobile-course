class SanitizedChatInput {
  const SanitizedChatInput({
    required this.text,
    required this.containsSensitiveData,
  });

  final String text;
  final bool containsSensitiveData;
}

abstract final class ChatSanitizer {
  static final _nikPattern = RegExp(r'(?<!\d)(?:\d[\s-]?){15}\d(?!\d)');
  static final _phonePattern = RegExp(
    r'(?<!\w)(?:\+?62|0)[\s().-]?(?:\d[\s().-]?){7,12}\d(?!\w)',
  );
  static final _unsafeControls = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]');

  /// Redacts Indonesian identity numbers and phone numbers before network use.
  static SanitizedChatInput sanitizeInput(String input) {
    var text = input;
    final hasSensitiveData =
        _nikPattern.hasMatch(text) || _phonePattern.hasMatch(text);
    text = text.replaceAll(_nikPattern, '[data pribadi disembunyikan]');
    text = text.replaceAll(_phonePattern, '[data pribadi disembunyikan]');
    return SanitizedChatInput(
      text: text.replaceAll(_unsafeControls, '').trim(),
      containsSensitiveData: hasSensitiveData,
    );
  }

  /// Removes invisible control characters and caps text before it reaches UI.
  static String sanitizeResponse(String response, {int maxLength = 2000}) {
    final clean = response.replaceAll(_unsafeControls, '').trim();
    if (clean.length <= maxLength) return clean;
    return '${clean.substring(0, maxLength).trimRight()}…';
  }
}
