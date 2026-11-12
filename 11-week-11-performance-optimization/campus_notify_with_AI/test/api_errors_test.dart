import 'package:campus_notify/core/api_errors.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Dio errors become user-friendly typed failures', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/notes'),
      type: DioExceptionType.connectionError,
      message: 'socket detail should not reach the UI',
    );

    final failure = mapApiError(error);

    expect(failure, isA<NetworkFailure>());
    expect(
      failure.message,
      'No internet connection. Check your network and try again.',
    );
    expect(failure.message, isNot(contains('socket detail')));
  });
}
