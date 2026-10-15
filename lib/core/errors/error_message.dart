import 'dart:async';
import 'dart:io';

import 'failure.dart';

const String genericErrorMessage = 'Something went wrong. Please try again.';
const String offlineMessage =
    "You're offline. Check your connection and try again.";
const String slowNetworkMessage =
    'This is taking longer than usual. Please try again.';

String userMessage(Object? error, {String fallback = genericErrorMessage}) {
  return switch (error) {
    SessionExpiredFailure(:final message) ||
    NetworkFailure(:final message) ||
    TimeoutFailure(:final message) => message,
    Failure(:final message, :final statusCode) => _failureMessage(
      message,
      statusCode,
      fallback,
    ),
    SocketException() => offlineMessage,
    TimeoutException() => slowNetworkMessage,
    _ => fallback,
  };
}

String _failureMessage(String message, int? statusCode, String fallback) {
  final readable = humanize(message, fallback: '');
  if (statusCode != null && statusCode >= 500) {
    return 'Something went wrong on our side. Please try again.';
  }
  if (readable.isNotEmpty) return readable;
  return switch (statusCode) {
    401 => 'Your session has expired. Please sign in again.',
    403 => "You don't have permission to do that.",
    404 => "We couldn't find that. It may have been removed.",
    409 => 'That has already been done.',
    422 || 400 => "That didn't work. Please check your details and try again.",
    429 => "You're doing that too often. Please wait a moment.",
    _ => fallback,
  };
}

const Map<String, String> _knownPhrases = {
  'unauthorized': 'Your session has expired. Please sign in again.',
  'forbidden': "You don't have permission to do that.",
  'forbidden resource': "You don't have permission to do that.",
  'not found': "We couldn't find that. It may have been removed.",
  'bad request': "That didn't work. Please check your details and try again.",
  'validation failed':
      'Some details are missing or invalid. Please check and try again.',
  'internal server error':
      'Something went wrong on our side. Please try again.',
  'bad gateway': 'Something went wrong on our side. Please try again.',
  'service unavailable':
      "We're having trouble right now. Please try again shortly.",
  'gateway timeout': slowNetworkMessage,
  'too many requests': "You're doing that too often. Please wait a moment.",
  'throttlerexception: too many requests':
      "You're doing that too often. Please wait a moment.",
  'conflict': 'That has already been done.',
  'request timed out': slowNetworkMessage,
  'no internet connection': offlineMessage,
  'network error occurred': offlineMessage,
};

// Server and SDK messages that leak implementation details are never shown
// to users; anything matching these falls back to a generic message.
final List<RegExp> _technicalPatterns = [
  RegExp(
    r'\bcannot (get|post|put|patch|delete|head|options)\b',
    caseSensitive: false,
  ),
  RegExp(r'https?://', caseSensitive: false),
  RegExp(r'(^|\s)/[a-z0-9_-]+/[a-z0-9_/:-]*', caseSensitive: false),
  RegExp(r'\b\w*(exception|error)\b\s*[:(]', caseSensitive: false),
  RegExp(
    r'\b(null check|nosuchmethod|is not a subtype|type .* is not|unexpected (token|character|end))\b',
    caseSensitive: false,
  ),
  RegExp(r'\.dart\b|#\d+\s|stack ?trace', caseSensitive: false),
  RegExp(r'^\s*[\[{]'),
  RegExp(r'"?(statusCode|status_code|errno|stack)"?\s*:', caseSensitive: false),
  RegExp(
    r'\bstatus(code)?\s*\d{3}\b|\b[45]\d\d\b\s*[:)]',
    caseSensitive: false,
  ),
  RegExp(r'\b[A-Z][A-Z0-9]*(_[A-Z0-9]+)+\b'),
  RegExp(r'\b\d{1,3}(\.\d{1,3}){3}\b'),
  RegExp(
    r'\b(sql|knex|prisma|postgres|redis|jwt|token is|econn\w*|enotfound)\b',
    caseSensitive: false,
  ),
];

String humanize(String? raw, {String fallback = genericErrorMessage}) {
  var text = (raw ?? '').trim();
  if (text.isEmpty) return fallback;

  text = text
      .replaceFirst(
        RegExp(r'^(_?Exception|Error):\s*', caseSensitive: false),
        '',
      )
      .trim();
  if (text.isEmpty) return fallback;

  final phrase =
      _knownPhrases[text.toLowerCase().replaceAll(RegExp(r'[.!]+$'), '')];
  if (phrase != null) return phrase;

  if (text.length > 160) return fallback;
  if (_technicalPatterns.any((pattern) => pattern.hasMatch(text))) {
    return fallback;
  }

  final sentence = text[0].toUpperCase() + text.substring(1);
  return RegExp(r'[.!?]$').hasMatch(sentence) ? sentence : '$sentence.';
}
