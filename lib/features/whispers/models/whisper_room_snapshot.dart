import 'package:equatable/equatable.dart';

class WhisperMember extends Equatable {
  const WhisperMember({
    required this.userId,
    required this.name,
    this.avatarUrl,
  });

  factory WhisperMember.fromJson(Map<String, dynamic> json) {
    final displayName = json['displayName'] as String?;
    final username = json['username'] as String?;
    return WhisperMember(
      userId: json['userId'] as String? ?? json['id'] as String? ?? '',
      name: displayName?.isNotEmpty == true ? displayName! : username ?? '',
      avatarUrl:
          json['profilePicture'] as String? ?? json['avatarUrl'] as String?,
    );
  }

  final String userId;
  final String name;
  final String? avatarUrl;

  @override
  List<Object?> get props => [userId, name, avatarUrl];
}

class WhisperRoomSnapshot extends Equatable {
  const WhisperRoomSnapshot({
    this.host,
    this.listenerCount = 0,
    this.listeners = const [],
  });

  factory WhisperRoomSnapshot.fromResponse(Object? response) {
    final data = response is Map<String, dynamic> ? response['data'] : null;
    final json = data is Map<String, dynamic>
        ? data
        : const <String, dynamic>{};
    final host = json['hostSummary'];
    final listeners = json['listeners'];
    return WhisperRoomSnapshot(
      host: host is Map<String, dynamic> ? WhisperMember.fromJson(host) : null,
      listenerCount: (json['listenerCount'] as num?)?.toInt() ?? 0,
      listeners: listeners is List
          ? listeners
                .whereType<Map<String, dynamic>>()
                .map(WhisperMember.fromJson)
                .where((m) => m.userId.isNotEmpty)
                .toList()
          : const [],
    );
  }

  final WhisperMember? host;
  final int listenerCount;
  final List<WhisperMember> listeners;

  @override
  List<Object?> get props => [host, listenerCount, listeners];
}
