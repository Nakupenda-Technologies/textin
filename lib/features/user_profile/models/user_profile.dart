import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.profilePicture,
    this.bio,
    this.isVerified = false,
    this.isBlocked = false,
    this.isMuted = false,
  });

  factory UserProfile.fromResponse(
    Object? response, {
    required bool isBlocked,
    required bool isMuted,
  }) {
    final data = response is Map<String, dynamic> ? response['data'] : null;
    final json = data is Map<String, dynamic> ? data : const {};
    final username = json['username'] as String? ?? '';
    final bio = (json['bio'] as String?)?.trim();
    return UserProfile(
      id: json['id'] as String? ?? '',
      username: username,
      displayName: json['displayName'] as String? ?? username,
      profilePicture: json['profilePicture'] as String?,
      bio: bio == null || bio.isEmpty ? null : bio,
      isVerified: json['isVerified'] as bool? ?? false,
      isBlocked: isBlocked,
      isMuted: isMuted,
    );
  }

  final String id;
  final String username;
  final String displayName;
  final String? profilePicture;
  final String? bio;
  final bool isVerified;
  final bool isBlocked;
  final bool isMuted;

  UserProfile copyWith({bool? isBlocked, bool? isMuted}) => UserProfile(
    id: id,
    username: username,
    displayName: displayName,
    profilePicture: profilePicture,
    bio: bio,
    isVerified: isVerified,
    isBlocked: isBlocked ?? this.isBlocked,
    isMuted: isMuted ?? this.isMuted,
  );

  @override
  List<Object?> get props => [
    id,
    username,
    displayName,
    profilePicture,
    bio,
    isVerified,
    isBlocked,
    isMuted,
  ];
}
