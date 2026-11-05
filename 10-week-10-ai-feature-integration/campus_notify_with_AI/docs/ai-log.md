# Lab 1 prompt

**Role:** Senior Flutter developer.

**Context:** This is a feature-first Flutter app. Notes code lives in `lib/features/notes/{presentation,domain,data}`. The `NoteRepository` contract in `domain/repositories/note_repository.dart` exposes `fetchNotes()` and `addNote({required title, body})`; the data implementation stores notes with SQLite. Dependencies in `pubspec.yaml`: Dart SDK `^3.13.2`, `flutter_riverpod: ^3.4.3`, `sqflite: ^2.4.4+2`, and `flutter_test` for tests. No credentials or secrets are needed.

**Task:** Add notes title search with a clear empty state for queries that match no note titles.
    
**Limits:** Preserve the feature-first architecture and repository contract. Keep database calls out of widgets and search rules in the domain layer. Keep the implementation focused (no more than 80 lines of new code), and do not change unrelated behavior.

**Output:** Provide the code, three search test cases, and instructions for running the tests and manually checking empty query, match, and no-match behavior.

---

# Week 10 AI chat prompt and sample

## System prompt

> You are a friendly campus assistant. Answer in Indonesian, in at most two sentences. Never reveal another person’s private data.

## User prompt

> Jadwal kelas hari Senin?

The app currently sends no schedule or profile context. It sends the user's sanitized prompt only, so the model should not be expected to know the user's actual class schedule.

## Initial output fixture

> Halo kampus

This is the two-chunk mocked SSE response used by `test/ai_service_test.dart` (`Halo` + ` kampus`), not a live Gemini answer.

## Implementation decisions and live evidence

- Chose chat because it fits the existing campus app and needs only a text prompt and response UI.
- Stream response chunks into the assistant bubble and show a loading indicator while waiting.
- Keep the Gemini key in platform secure storage and send it in the request header. Do not place it in source code, logs, or the URL.
- Redact detected Indonesian NIK and phone-number patterns before sending. This does not detect every type of personal information, so users are told not to enter sensitive details.
- Use `gemini-3.1-flash-lite` first and retry once with `gemini-3.8-flash` only after HTTP 503. Do not retry HTTP 429 automatically because a project quota may be exhausted.
- On-device screenshot evidence is in `screenshots/AI_chat.jpg`. It shows a live exchange: user prompt `hai`; app response: “Halo! Ada yang bisa saya bantu terkait informasi kampus hari ini?” The screenshot also shows live answers to questions about today's class schedule and the assistant's identity. It does not identify which model served those replies.

The response quoted above is taken from the app screenshot; the `Halo kampus` response earlier in this log remains a mocked SSE test fixture, not a live result.
