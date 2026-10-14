import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/errors/error_message.dart';
import 'package:textin/core/errors/failure.dart';

void main() {
  group('humanize', () {
    test('keeps readable server messages and ends them with a period', () {
      expect(
        humanize('invalid username or password'),
        'Invalid username or password.',
      );
    });

    test('maps known short phrases to friendly sentences', () {
      expect(humanize('Unauthorized'), contains('session has expired'));
      expect(humanize('Too Many Requests'), contains('too often'));
    });

    test('hides technical details behind the fallback', () {
      for (final raw in [
        'Cannot POST /auth/login',
        'SocketException: Failed host lookup',
        '{"statusCode":500}',
        "Null check operator used on a null value",
        'ECONNREFUSED 127.0.0.1',
        'USER_NOT_FOUND',
      ]) {
        expect(humanize(raw), genericErrorMessage, reason: raw);
      }
    });

    test('falls back on empty input', () {
      expect(humanize(null), genericErrorMessage);
      expect(humanize('   '), genericErrorMessage);
    });
  });

  group('userMessage', () {
    test('uses network specific copy', () {
      expect(userMessage(const NetworkFailure()), offlineMessage);
      expect(userMessage(const SocketException('x')), offlineMessage);
      expect(userMessage(TimeoutException('x')), slowNetworkMessage);
    });

    test('never surfaces server error details for 5xx', () {
      expect(
        userMessage(
          const ServerFailure('relation users does not exist', statusCode: 500),
        ),
        'Something went wrong on our side. Please try again.',
      );
    });

    test('uses status based copy when the server message is technical', () {
      expect(
        userMessage(const ServerFailure('THROTTLED_REQUEST', statusCode: 429)),
        "You're doing that too often. Please wait a moment.",
      );
    });

    test('returns the fallback for unknown error types', () {
      expect(userMessage(StateError('boom')), genericErrorMessage);
    });
  });
}
