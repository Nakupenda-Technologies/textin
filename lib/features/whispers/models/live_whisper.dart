import 'package:equatable/equatable.dart';

class LiveWhisper extends Equatable {
  const LiveWhisper({
    required this.id,
    this.hostId = '',
    required this.title,
    required this.hostDisplayName,
    this.hostUsername = '',
    this.hostProfilePicture,
    this.hostIsVerified = false,
    this.listenerCount = 0,
    this.chargeListeners = false,
  });

  factory LiveWhisper.fromJson(Map<String, dynamic> json) => LiveWhisper(
    id: json['id'] as String? ?? '',
    hostId: json['hostId'] as String? ?? '',
    title: json['title'] as String? ?? '',
    hostDisplayName: json['hostDisplayName'] as String? ?? '',
    hostUsername: json['hostUsername'] as String? ?? '',
    hostProfilePicture: json['hostProfilePicture'] as String?,
    hostIsVerified: json['hostIsVerified'] as bool? ?? false,
    listenerCount: (json['listenerCount'] as num?)?.toInt() ?? 0,
    chargeListeners: json['chargeListeners'] as bool? ?? false,
  );

  static List<LiveWhisper> listFromResponse(Object? response) {
    final data = response is Map<String, dynamic> ? response['data'] : null;
    final items = data is Map<String, dynamic> ? data['items'] : null;
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(LiveWhisper.fromJson)
        .where((w) => w.id.isNotEmpty)
        .toList();
  }

  final String id;
  final String hostId;
  final String title;
  final String hostDisplayName;
  final String hostUsername;
  final String? hostProfilePicture;
  final bool hostIsVerified;
  final int listenerCount;
  final bool chargeListeners;

  @override
  List<Object?> get props => [
    id,
    hostId,
    title,
    hostDisplayName,
    hostUsername,
    hostProfilePicture,
    hostIsVerified,
    listenerCount,
    chargeListeners,
  ];
}
