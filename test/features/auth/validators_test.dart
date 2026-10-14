import 'package:flutter_test/flutter_test.dart';
import 'package:textin/features/auth/validators.dart';

void main() {
  test('login only requires both fields so older passwords still work', () {
    expect(AuthValidators.identifier('  '), 'Enter your email or username.');
    expect(AuthValidators.identifier('slim'), isNull);
    expect(AuthValidators.loginPassword(''), 'Enter your password.');
    expect(AuthValidators.loginPassword('abc'), isNull);
  });

  test('names accept international letters and common punctuation', () {
    expect(
      AuthValidators.name("Zoë O'Neil-Ávila", field: 'first name'),
      isNull,
    );
    expect(
      AuthValidators.name('', field: 'first name'),
      'Enter your first name.',
    );
    expect(
      AuthValidators.name('R2D2', field: 'last name'),
      'Your last name can only contain letters, spaces, hyphens and apostrophes.',
    );
  });

  test('email and username formats', () {
    expect(AuthValidators.email('slim@example.com'), isNull);
    expect(AuthValidators.email('slim@'), 'Enter a valid email address.');
    expect(AuthValidators.username('sl'), contains('at least 3'));
    expect(
      AuthValidators.username('slim boogie'),
      contains('letters, numbers'),
    );
    expect(AuthValidators.username('slim.boogie_1'), isNull);
  });

  test('new passwords need length, a letter and a number', () {
    expect(AuthValidators.newPassword('short1'), contains('at least 8'));
    expect(
      AuthValidators.newPassword('longpassword'),
      'Use at least one letter and one number.',
    );
    expect(AuthValidators.newPassword('longpass1'), isNull);
    expect(
      AuthValidators.confirmPassword('longpass2', 'longpass1'),
      'The passwords do not match.',
    );
  });

  test('date of birth enforces the minimum age on the exact day', () {
    final now = DateTime(2026, 10, 14);
    expect(AuthValidators.dateOfBirth(DateTime(2008, 10, 14), now), isNull);
    expect(
      AuthValidators.dateOfBirth(DateTime(2008, 10, 15), now),
      'You must be at least 18 years old to join Textin.',
    );
    expect(AuthValidators.dateOfBirth(null, now), 'Select your date of birth.');
  });
}
