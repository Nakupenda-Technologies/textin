import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.profilePicture,
    this.bio,
  });

  final String id;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? profilePicture;
  final String? bio;

  String get displayName {
    final fullName = [
      firstName,
      lastName,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
    if (fullName.isNotEmpty) return fullName;
    return username ?? '';
  }

  static AuthUser? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final source = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final id = _string(source['id']);
    if (id == null) return null;

    return AuthUser(
      id: id,
      username: _string(source['username']),
      firstName: _string(source['firstName']),
      lastName: _string(source['lastName']),
      email: _string(source['email']),
      profilePicture: _string(source['profilePicture']),
      bio: _string(source['bio']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'profilePicture': profilePicture,
    'bio': bio,
  };

  static String? _string(Object? value) => switch (value) {
    String text when text.trim().isNotEmpty => text,
    num number => number.toString(),
    _ => null,
  };

  @override
  List<Object?> get props => [
    id,
    username,
    firstName,
    lastName,
    email,
    profilePicture,
    bio,
  ];
}
