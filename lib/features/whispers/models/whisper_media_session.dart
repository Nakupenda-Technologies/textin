import 'package:equatable/equatable.dart';

class WhisperMediaSession extends Equatable {
  const WhisperMediaSession({
    required this.roomName,
    required this.accessToken,
    this.canPublishAudio = false,
  });

  factory WhisperMediaSession.fromResponse(Object? response) {
    final data = response is Map<String, dynamic> ? response['data'] : null;
    final json = data is Map<String, dynamic> ? data : const {};
    return WhisperMediaSession(
      roomName: json['roomName'] as String? ?? '',
      accessToken: json['accessToken'] as String? ?? '',
      canPublishAudio: json['canPublishAudio'] as bool? ?? false,
    );
  }

  final String roomName;
  final String accessToken;
  final bool canPublishAudio;

  @override
  List<Object?> get props => [roomName, accessToken, canPublishAudio];
}
