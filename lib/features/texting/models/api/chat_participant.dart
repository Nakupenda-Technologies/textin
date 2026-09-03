import 'package:equatable/equatable.dart';

class ChatParticipant extends Equatable {
  const ChatParticipant({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.isVerified,
    this.profilePictureUrl,
    this.lastSeen,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      displayName: json['displayName'] as String? ?? json['username'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : null,
    );
  }

  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String displayName;
  final bool isVerified;
  final String? profilePictureUrl;
  final DateTime? lastSeen;

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'firstName': firstName,
    'lastName': lastName,
    'displayName': displayName,
    'isVerified': isVerified,
    if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
    if (lastSeen != null) 'lastSeen': lastSeen!.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    username,
    firstName,
    lastName,
    displayName,
    isVerified,
    profilePictureUrl,
    lastSeen,
  ];
}
