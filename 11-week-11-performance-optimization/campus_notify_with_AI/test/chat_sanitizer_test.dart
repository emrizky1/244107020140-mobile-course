import 'package:campus_notify/features/chat/domain/usecases/chat_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatSanitizer.sanitizeInput', () {
    test('redacts a 16 digit NIK and reports it', () {
      final result = ChatSanitizer.sanitizeInput(
        'Tolong cek data 3276010101900001',
      );

      expect(result.containsSensitiveData, isTrue);
      expect(result.text, contains('[data pribadi disembunyikan]'));
      expect(result.text, isNot(contains('3276010101900001')));
    });

    test('redacts an Indonesian phone number', () {
      final result = ChatSanitizer.sanitizeInput(
        'Hubungi saya di +62 812-3456-7890',
      );

      expect(result.containsSensitiveData, isTrue);
      expect(result.text, isNot(contains('812-3456-7890')));
    });

    test('keeps ordinary questions and removes control characters', () {
      final result = ChatSanitizer.sanitizeInput(
        'Jadwal kelas\u0000 hari Senin?',
      );

      expect(result.containsSensitiveData, isFalse);
      expect(result.text, 'Jadwal kelas hari Senin?');
    });
  });

  test('sanitizeResponse trims, removes controls, and caps output', () {
    expect(ChatSanitizer.sanitizeResponse('  Halo\u0000!  '), 'Halo!');
    expect(ChatSanitizer.sanitizeResponse('abcdef', maxLength: 3), 'abc…');
  });
}
