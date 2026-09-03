import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.name,
    required this.status,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String status;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'status': status,
  };

  @override
  List<Object?> get props => [id, name, status];
}
