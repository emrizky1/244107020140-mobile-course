import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Friendly, displayable errors from the AI service.
final class AiServiceException implements Exception {
  const AiServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Calls Gemini's streaming text endpoint and keeps its API key in secure storage.
class AiService {
  AiService({
    FlutterSecureStorage? storage,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
    this.model = 'gemini-3.1-flash-lite',
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  static const apiKeyStorageKey = 'ai_api_key';
  static const fallbackModel = 'gemini-3.8-flash';
  static const systemPrompt =
      'You are a friendly campus assistant. Answer in Indonesian, in at most '
      'two sentences. Never reveal another person’s private data.';
  static const _baseUrl = 'generativelanguage.googleapis.com';

  final FlutterSecureStorage _storage;
  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;
  final String model;

  Future<void> saveApiKey(String key) async {
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) {
      throw const AiServiceException('Masukkan API key terlebih dahulu.');
    }
    try {
      await _storage.write(key: apiKeyStorageKey, value: normalizedKey);
    } catch (_) {
      throw const AiServiceException('API key gagal disimpan dengan aman.');
    }
  }

  Future<void> clearApiKey() async {
    try {
      await _storage.delete(key: apiKeyStorageKey);
    } catch (_) {
      throw const AiServiceException('API key gagal dihapus.');
    }
  }

  /// Emits response text as Gemini sends SSE chunks.
  Stream<String> askStream(String question) async* {
    final prompt = question.trim();
    if (prompt.isEmpty) {
      throw const AiServiceException('Tulis pertanyaan terlebih dahulu.');
    }

    final apiKey = (await _readApiKey()).trim();
    if (apiKey.isEmpty) {
      throw const AiServiceException(
        'API key belum tersedia. Tambahkan di pengaturan AI.',
      );
    }

    try {
      var response = await _client
          .send(_buildRequest(prompt, apiKey, model))
          .timeout(timeout);
      if (response.statusCode == 503 && model != fallbackModel) {
        // The original response stream must be consumed before retrying.
        await _readProviderError(response.stream, apiKey);
        response = await _client
            .send(_buildRequest(prompt, apiKey, fallbackModel))
            .timeout(timeout);
      }
      if (response.statusCode == 429) {
        final details = await _readProviderError(response.stream, apiKey);
        final suffix = details == null ? '' : ' Detail: $details';
        throw AiServiceException(
          'Layanan AI membatasi permintaan (HTTP 429). Tunggu lalu coba lagi.$suffix',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final details = await _readProviderError(response.stream, apiKey);
        throw AiServiceException(
          _httpErrorMessage(response.statusCode, details),
        );
      }

      var receivedText = false;
      await for (final part in _readSse(response.stream)) {
        receivedText = true;
        yield part;
      }
      if (!receivedText) {
        throw const AiServiceException(
          'Layanan AI tidak mengirim jawaban. Coba lagi.',
        );
      }
    } on AiServiceException {
      rethrow;
    } on TimeoutException {
      throw const AiServiceException(
        'Permintaan AI terlalu lama. Periksa koneksi lalu coba lagi.',
      );
    } on http.ClientException {
      throw const AiServiceException(
        'Tidak dapat terhubung ke layanan AI. Periksa koneksi internet.',
      );
    } on FormatException {
      throw const AiServiceException(
        'Jawaban dari layanan AI tidak dapat dibaca. Coba lagi.',
      );
    } catch (_) {
      throw const AiServiceException(
        'Terjadi kesalahan saat meminta jawaban AI. Coba lagi.',
      );
    }
  }

  http.Request _buildRequest(String prompt, String apiKey, String modelName) {
    final uri = Uri.https(
      _baseUrl,
      '/v1beta/models/$modelName:streamGenerateContent',
      {'alt': 'sse'},
    );
    return http.Request('POST', uri)
      ..headers.addAll({
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'text/event-stream',
        'x-goog-api-key': apiKey,
      })
      ..body = jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'generationConfig': {'maxOutputTokens': 256},
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      });
  }

  String _httpErrorMessage(int statusCode, String? details) {
    final detailSuffix = details == null ? '' : ' Detail: $details';
    final message = switch (statusCode) {
      400 =>
        'Permintaan AI ditolak (HTTP 400). Periksa konfigurasi Gemini API.',
      401 || 403 =>
        'API key ditolak atau tidak memiliki akses (HTTP $statusCode). Pastikan key berasal dari Google AI Studio.',
      404 => 'Model Gemini tidak ditemukan (HTTP 404). Periksa ketersediaan model untuk project ini.',
      503 => 'API mengembalikan HTTP 503. Periksa detail server dan coba lagi nanti.',
      >= 500 => 'API mengembalikan HTTP $statusCode. Coba lagi nanti.',
      _ => 'Layanan AI menolak permintaan (HTTP $statusCode). Coba lagi nanti.',
    };
    return '$message$detailSuffix';
  }

  Future<String?> _readProviderError(
    Stream<List<int>> responseBytes,
    String apiKey,
  ) async {
    try {
      final body = await responseBytes
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final error = decoded['error'];
      if (error is! Map<String, dynamic>) return null;

      final status = error['status'];
      final message = error['message'];
      final details = [
        if (status is String && status.isNotEmpty) status,
        if (message is String && message.isNotEmpty) message,
      ].join(': ');
      if (details.isEmpty) return null;

      final sanitizedDetails = details
          .replaceAll(apiKey, '[key disamarkan]')
          .replaceAll(RegExp(r'[\x00-\x1F\x7F]+'), ' ')
          .trim();
      if (sanitizedDetails.length <= 220) return sanitizedDetails;
      return '${sanitizedDetails.substring(0, 220)}…';
    } catch (_) {
      return null;
    }
  }

  Future<String> _readApiKey() async {
    try {
      return await _storage.read(key: apiKeyStorageKey) ?? '';
    } catch (_) {
      throw const AiServiceException('API key gagal dibaca dari penyimpanan.');
    }
  }

  Stream<String> _readSse(Stream<List<int>> bytes) async* {
    var dataLines = <String>[];
    await for (final line
        in bytes
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .timeout(timeout)) {
      if (line.isEmpty) {
        if (dataLines.isNotEmpty) {
          yield* _decodeEvent(dataLines.join('\n'));
          dataLines = [];
        }
      } else if (line.startsWith('data:')) {
        var data = line.substring(5);
        if (data.startsWith(' ')) data = data.substring(1);
        dataLines.add(data);
      }
    }
    if (dataLines.isNotEmpty) yield* _decodeEvent(dataLines.join('\n'));
  }

  Stream<String> _decodeEvent(String data) async* {
    if (data == '[DONE]') return;
    final decoded = jsonDecode(data);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object.');
    }

    final candidates = decoded['candidates'];
    if (candidates == null) {
      // Gemini can send metadata-only events without candidates.
      return;
    }
    if (candidates is! List) {
      throw const FormatException('Invalid candidates field.');
    }
    if (candidates.isEmpty) return;

    final candidate = candidates.first;
    if (candidate is! Map<String, dynamic>) {
      throw const FormatException('Invalid candidate.');
    }
    final content = candidate['content'];
    if (content == null) return;
    if (content is! Map<String, dynamic>) {
      throw const FormatException('Invalid content field.');
    }
    final parts = content['parts'];
    if (parts == null) return;
    if (parts is! List) throw const FormatException('Invalid parts field.');

    for (final part in parts) {
      if (part is! Map<String, dynamic>) continue;
      if (part['thought'] == true) continue;
      final text = part['text'];
      if (text is String && text.isNotEmpty) yield text;
    }
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
