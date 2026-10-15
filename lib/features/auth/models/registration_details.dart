enum Gender {
  male('Male'),
  female('Female'),
  other('Other');

  const Gender(this.label);

  final String label;

  String get apiValue => name;
}

class BasicInfo {
  const BasicInfo({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    this.referralCode,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String? referralCode;

  Map<String, dynamic> toPayload() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'username': username,
    'referralCode': ?referralCode,
  };
}
