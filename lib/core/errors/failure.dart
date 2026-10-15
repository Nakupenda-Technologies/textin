import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = "You're offline. Check your connection and try again.",
    int? statusCode,
  ]) : super(statusCode: statusCode);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([
    super.message = 'This is taking longer than usual. Please try again.',
  ]);
}

class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([
    super.message = 'Your session has expired. Please sign in again.',
  ]) : super(statusCode: 401);
}

class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'Something went wrong. Please try again.',
    int? statusCode,
  ]) : super(statusCode: statusCode);
}
