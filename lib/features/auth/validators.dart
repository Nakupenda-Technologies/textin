class AuthValidators {
  AuthValidators._();

  static const int minimumAge = 18;
  static const int minimumPasswordLength = 8;

  static final RegExp _email = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$",
  );
  static final RegExp _name = RegExp(r"^[\p{L}][\p{L} '\-.]*$", unicode: true);
  static final RegExp _username = RegExp(r'^[A-Za-z0-9_.]+$');

  static String? identifier(String value) =>
      value.trim().isEmpty ? 'Enter your email or username.' : null;

  static String? loginPassword(String value) =>
      value.isEmpty ? 'Enter your password.' : null;

  static String? name(String value, {required String field}) {
    final text = value.trim();
    if (text.isEmpty) return 'Enter your $field.';
    if (text.length > 50) return 'Your $field must be 50 characters or fewer.';
    if (!_name.hasMatch(text)) {
      return 'Your $field can only contain letters, spaces, hyphens and apostrophes.';
    }
    return null;
  }

  static String? email(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'Enter your email address.';
    if (!_email.hasMatch(text)) return 'Enter a valid email address.';
    return null;
  }

  static String? username(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'Choose a username.';
    if (text.length < 3) return 'Your username must be at least 3 characters.';
    if (text.length > 30) {
      return 'Your username must be 30 characters or fewer.';
    }
    if (!_username.hasMatch(text)) {
      return 'Use only letters, numbers, underscores and full stops.';
    }
    return null;
  }

  static String? newPassword(String value) {
    if (value.isEmpty) return 'Create a password.';
    if (value.length < minimumPasswordLength) {
      return 'Your password must be at least $minimumPasswordLength characters.';
    }
    if (!value.contains(RegExp(r'[A-Za-z]')) ||
        !value.contains(RegExp(r'\d'))) {
      return 'Use at least one letter and one number.';
    }
    return null;
  }

  static String? confirmPassword(String value, String password) {
    if (value.isEmpty) return 'Confirm your password.';
    if (value != password) return 'The passwords do not match.';
    return null;
  }

  static DateTime latestAllowedBirthDate([DateTime? now]) {
    final today = now ?? DateTime.now();
    return DateTime(today.year - minimumAge, today.month, today.day);
  }

  static String? dateOfBirth(DateTime? value, [DateTime? now]) {
    if (value == null) return 'Select your date of birth.';
    if (value.isAfter(latestAllowedBirthDate(now))) {
      return 'You must be at least $minimumAge years old to join Textin.';
    }
    return null;
  }
}
