import 'package:dio/dio.dart';

import 'failures.dart';

/// Maps transport exceptions to typed failures with user-friendly messages.
///
/// The UI receives the failure's [Failure.message], never the raw exception.
Failure mapApiError(Object error) {
  if (error is Failure) return error;
  if (error is DioException) {
    // Connection-level failures (no response from server).
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkFailure(
          'Server is taking too long to respond. Please try again.',
        );
      case DioExceptionType.connectionError:
        return const NetworkFailure(
          'No internet connection. Check your network and try again.',
        );
      case DioExceptionType.cancel:
        return const NetworkFailure('Request was cancelled.');
      case DioExceptionType.badCertificate:
        return const NetworkFailure(
          'Secure connection failed. Please contact support.',
        );
      case DioExceptionType.badResponse:
        return NetworkFailure(_mapStatusCode(error.response?.statusCode));
      case DioExceptionType.unknown:
        return const NetworkFailure(
          'An unexpected network error occurred. Please try again.',
        );
    }
  }
  return const NetworkFailure('Something went wrong. Please try again.');
}

String _mapStatusCode(int? code) {
  if (code == null) return 'Unexpected error. Please try again.';
  return switch (code) {
    400 => 'Invalid request. Please check your input.',
    401 => 'Session expired. Please log in again.',
    403 => 'You don\'t have permission to perform this action.',
    404 => 'The requested resource was not found.',
    409 => 'Conflict — the data may have been updated. Refresh and retry.',
    422 => 'The server could not process your request. Check your input.',
    429 => 'Too many requests. Please wait a moment and try again.',
    >= 500 && < 600 => 'Server error. Please try again later.',
    _ => 'Unexpected error (code $code). Please try again.',
  };
}
