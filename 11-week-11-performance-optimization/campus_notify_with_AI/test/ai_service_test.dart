import 'dart:convert';

import 'package:campus_notify/ai/ai_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late _MemorySecureStorage storage;

  setUp(() {
    storage = _MemorySecureStorage({
      AiService.apiKeyStorageKey: 'dummy-test-value',
    });
  });

  test('streams SSE text and sends API key in header', () async {
    http.BaseRequest? sentRequest;
    String? sentBody;
    final client = MockClient((request) async {
      sentRequest = request;
      sentBody = request.body;
      return http.Response(
        'data: {"candidates":[{"content":{"parts":[{"text":"Halo"}]}}]}\n\n'
        'data: {"candidates":[{"content":{"parts":[{"text":" kampus"}]}}]}\n\n',
        200,
        headers: {'content-type': 'text/event-stream'},
      );
    });
    final service = AiService(client: client, storage: storage);
    addTearDown(client.close);

    final chunks = await service.askStream('Apa kabar?').toList();

    expect(chunks, ['Halo', ' kampus']);
    expect(sentRequest?.headers['x-goog-api-key'], 'dummy-test-value');
    expect(sentRequest?.url.queryParameters, {'alt': 'sse'});
    final payload = jsonDecode(sentBody!);
    expect(
      payload['systemInstruction']['parts'][0]['text'],
      contains('Indonesian'),
    );
  });

  test('reports a missing API key without sending an HTTP request', () async {
    storage.values.clear();
    var requestSent = false;
    final client = MockClient((_) async {
      requestSent = true;
      return http.Response('', 200);
    });
    final service = AiService(client: client, storage: storage);
    addTearDown(client.close);

    await expectLater(
      service.askStream('Pertanyaan').toList(),
      throwsA(
        isA<AiServiceException>().having(
          (error) => error.message,
          'message',
          contains('API key belum tersedia'),
        ),
      ),
    );
    expect(requestSent, isFalse);
  });

  test('maps rate limiting to a friendly error', () async {
    final client = MockClient((_) async => http.Response('', 429));
    final service = AiService(client: client, storage: storage);
    addTearDown(client.close);

    await expectLater(
      service.askStream('Pertanyaan').toList(),
      throwsA(
        isA<AiServiceException>().having(
          (error) => error.message,
          'message',
          contains('membatasi permintaan'),
        ),
      ),
    );
  });

  test('shows sanitized provider details for rate limits', () async {
    final client = MockClient(
      (_) async => http.Response(
        '{"error":{"status":"RESOURCE_EXHAUSTED","message":"Quota reached for dummy-test-value"}}',
        429,
      ),
    );
    final service = AiService(client: client, storage: storage);
    addTearDown(client.close);

    await expectLater(
      service.askStream('Pertanyaan').toList(),
      throwsA(
        isA<AiServiceException>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('HTTP 429'),
            contains('RESOURCE_EXHAUSTED'),
            contains('[key disamarkan]'),
            isNot(contains('dummy-test-value')),
          ),
        ),
      ),
    );
  });

  test('explains authorization errors without exposing the key', () async {
    final client = MockClient((_) async => http.Response('', 403));
    final service = AiService(client: client, storage: storage);
    addTearDown(client.close);

    await expectLater(
      service.askStream('Pertanyaan').toList(),
      throwsA(
        isA<AiServiceException>().having(
          (error) => error.message,
          'message',
          allOf(contains('HTTP 403'), contains('Google AI Studio')),
        ),
      ),
    );
  });

  test('includes sanitized provider details for HTTP 503', () async {
    final client = MockClient(
      (_) async => http.Response(
        '{"error":{"status":"UNAVAILABLE","message":"Overloaded dummy-test-value"}}',
        503,
      ),
    );
    final service = AiService(client: client, storage: storage);
    addTearDown(client.close);

    await expectLater(
      service.askStream('Pertanyaan').toList(),
      throwsA(
        isA<AiServiceException>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('HTTP 503'),
            contains('UNAVAILABLE'),
            contains('[key disamarkan]'),
            isNot(contains('dummy-test-value')),
          ),
        ),
      ),
    );
  });

  test('maps offline connection errors to a friendly message', () async {
    final client = MockClient((_) async {
      throw http.ClientException('offline');
    });
    final service = AiService(client: client, storage: storage);
    addTearDown(client.close);

    await expectLater(
      service.askStream('Pertanyaan').toList(),
      throwsA(
        isA<AiServiceException>().having(
          (error) => error.message,
          'message',
          contains('Periksa koneksi internet'),
        ),
      ),
    );
  });

  test('rejects empty and malformed SSE responses', () async {
    for (final body in ['', 'data: not-json\n\n']) {
      final client = MockClient((_) async => http.Response(body, 200));
      final service = AiService(client: client, storage: storage);
      addTearDown(client.close);

      await expectLater(
        service.askStream('Pertanyaan').toList(),
        throwsA(isA<AiServiceException>()),
      );
    }
  });

  test('saves a trimmed key in secure storage', () async {
    final client = MockClient((_) async => http.Response('', 200));
    final service = AiService(client: client, storage: storage);
    addTearDown(client.close);

    await service.saveApiKey('  another-secret  ');

    expect(storage.values[AiService.apiKeyStorageKey], 'another-secret');
  });
}

class _MemorySecureStorage extends FlutterSecureStorage {
  _MemorySecureStorage([Map<String, String>? initialValues])
    : values = initialValues ?? {};

  final Map<String, String> values;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}
