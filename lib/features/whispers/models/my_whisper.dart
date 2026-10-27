import 'package:equatable/equatable.dart';

enum WhisperStatus { draft, scheduled, live, ended }

class MyWhisper extends Equatable {
  const MyWhisper({
    required this.id,
    required this.title,
    required this.status,
    this.isPrivate = false,
    this.scheduledAt,
    this.startedAt,
    this.endedAt,
  });

  factory MyWhisper.fromJson(Map<String, dynamic> json) => MyWhisper(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    status:
        WhisperStatus.values.asNameMap()[json['status']] ?? WhisperStatus.draft,
    isPrivate: json['visibility'] == 'private',
    scheduledAt: _localTime(json['scheduledAt']),
    startedAt: _localTime(json['startedAt']),
    endedAt: _localTime(json['endedAt']),
  );

  static DateTime? _localTime(Object? value) =>
      DateTime.tryParse(value as String? ?? '')?.toLocal();

  static List<MyWhisper> listFromResponse(Object? response) {
    final data = response is Map<String, dynamic> ? response['data'] : null;
    final items = data is Map<String, dynamic> ? data['items'] : null;
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(MyWhisper.fromJson)
        .where((w) => w.id.isNotEmpty)
        .toList();
  }

  final String id;
  final String title;
  final WhisperStatus status;
  final bool isPrivate;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  Duration? get duration => switch ((startedAt, endedAt)) {
    (final start?, final end?) => end.difference(start),
    _ => null,
  };

  @override
  List<Object?> get props => [
    id,
    title,
    status,
    isPrivate,
    scheduledAt,
    startedAt,
    endedAt,
  ];
}
