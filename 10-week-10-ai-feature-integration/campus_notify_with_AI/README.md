# Week 10: AI Feature Integration

## AI campus chat

The app includes an optional Gemini-powered campus chat. Open **AI Chat** from
the home screen and add a Gemini API key using the key icon. The key is stored
with `flutter_secure_storage`; it is sent to Google's API in the
`x-goog-api-key` request header and is not written to source, logs, or the URL.
Remove the key from the app's secure storage if it should no longer be used.

The chat flow follows the project dependency rule:

```text
Chat screen -> Riverpod ChatNotifier -> AiRepository -> AiService
```

The notifier streams answer chunks into the message list, offers retry on
failure, caches up to 30 successful answers in memory, and applies a two-second
cooldown to fresh requests. Repeated questions served from memory do not call
the API. The cache is cleared when the app process exits.

### Privacy and cost risks

| Risk | Mitigation |
| --- | --- |
| NIK or phone number sent to the model | Detect common 16-digit NIK and Indonesian phone patterns, redact them before the API request, and show a warning. |
| API key exposure | Store the key in platform secure storage and send it in the request header; never log it or include it in a URL. |
| Unexpected model output | Remove control characters, cap displayed output at 2,000 characters, and show an error for empty or malformed responses. |
| Excessive requests/cost | Two-second cooldown, in-memory cache for repeated questions, and Gemini rate-limit errors surfaced with retry. |
| API unavailable/offline | The app tries `gemini-3.1-flash-lite` first. On HTTP 503 overload, it retries once with `gemini-3.8-flash`; other failures show a friendly error and retry action. HTTP 429 quota/rate limits are not retried with another model. Chat answers are not available offline. |

Only the user's sanitized question and the fixed system instruction are sent;
the app currently does not attach schedules, profiles, or other context. Avoid
entering sensitive information even though the client redacts detected number
patterns. Client-side redaction is a guardrail, not a guarantee that every
personal detail can be identified.

### Verification

Run `flutter analyze` and `flutter test`. Unit tests cover redaction, output
validation, secure key handling, SSE parsing, streaming chunks, missing keys,
offline errors, rate limits, and empty/malformed responses. To manually check
the live flow, install the app on a device or emulator, save a valid Gemini API
key in AI Chat settings, ask a non-sensitive question, and confirm the answer
arrives progressively. Also try a blank key, airplane mode, a rate-limited key,
and a question containing a test phone/NIK pattern. Live API behavior requires
an active key and network connection.

Latest verification: `flutter analyze` reported no issues, `flutter test` passed
all 33 tests, and `flutter build apk --debug` succeeded.

The API key belongs to the client device in this educational implementation.
For a production app, put the Gemini API credential behind an authenticated
backend to avoid distributing a reusable key in the mobile client.

## Reflection

- **Which AI feature did you integrate and why?** I integrated a streaming campus chat because it fits the app and the codelab already outlines a chat flow.
- **How do you protect user privacy when using an AI API?** I store the user's API key in platform secure storage and send it in a request header, never in the source code or URL. Before sending a question, the app redacts detected NIK and Indonesian phone number patterns, shows a warning, and sends only the sanitized question with a short system prompt. Users should still avoid entering sensitive details because pattern matching cannot detect every kind of private information.
- **What fallback do you provide if the AI service errors?** On HTTP 503, the app retries once with `gemini-3.8-flash` after trying `gemini-3.1-flash-lite`. For missing keys, connection problems, rate limits, malformed or empty responses, and timeouts, it shows a friendly error and retry action. It also caches successful repeated questions in memory, but has no offline answer source.
- **What did you learn about AI feature UX on mobile?** Showing streamed text and a loading indicator gives feedback while the model is working. Disabling send during a request and offering a clear retry action make delays and errors easier to understand.
