import 'package:equatable/equatable.dart';

class FollowingUser extends Equatable {
  const FollowingUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.profilePicture,
    this.bio,
    this.isVerified = false,
  });

  factory FollowingUser.fromJson(Map<String, dynamic> json) {
    return FollowingUser(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName:
          json['displayName'] as String? ?? json['username'] as String? ?? '',
      profilePicture: json['profilePicture'] as String?,
      bio: json['bio'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  final String id;
  final String username;
  final String displayName;
  final String? profilePicture;
  final String? bio;
  final bool isVerified;

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'displayName': displayName,
    if (profilePicture != null) 'profilePicture': profilePicture,
    if (bio != null) 'bio': bio,
    'isVerified': isVerified,
  };

  @override
  List<Object?> get props => [
    id,
    username,
    displayName,
    profilePicture,
    bio,
    isVerified,
  ];
}
