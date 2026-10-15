import 'package:equatable/equatable.dart';

class ListedUser extends Equatable {
  const ListedUser({
    required this.id,
    required this.displayName,
    this.username,
    this.profilePicture,
  });

  factory ListedUser.fromResponse(String id, Object? response) {
    final data = response is Map<String, dynamic> ? response['data'] : null;
    final json = data is Map<String, dynamic> ? data : const {};
    final username = json['username'] as String?;
    return ListedUser(
      id: id,
      displayName: json['displayName'] as String? ?? username ?? 'Unknown user',
      username: username,
      profilePicture: json['profilePicture'] as String?,
    );
  }

  final String id;
  final String displayName;
  final String? username;
  final String? profilePicture;

  @override
  List<Object?> get props => [id, displayName, username, profilePicture];
}
