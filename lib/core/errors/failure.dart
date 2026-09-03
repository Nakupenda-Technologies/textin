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
    super.message = 'No internet connection',
    int? statusCode,
  ]) : super(statusCode: statusCode);
}

class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'An unexpected error occurred',
    int? statusCode,
  ]) : super(statusCode: statusCode);
}
