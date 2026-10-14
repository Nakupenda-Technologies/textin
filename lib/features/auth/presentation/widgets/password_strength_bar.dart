import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../shared/theme/app_theme.dart';

enum PasswordStrength {
  none(0, ''),
  weak(1, 'Weak'),
  fair(2, 'Fair'),
  strong(3, 'Strong');

  const PasswordStrength(this.score, this.label);

  final int score;
  final String label;

  static PasswordStrength of(String password) {
    if (password.isEmpty) return none;
    var score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Za-z]')) &&
        password.contains(RegExp(r'\d'))) {
      score++;
    }
    if (password.length >= 12 || password.contains(RegExp(r'[^A-Za-z\d]'))) {
      score++;
    }
    return switch (score) {
      <= 1 => weak,
      2 => fair,
      _ => strong,
    };
  }

  Color get color => switch (this) {
    none || weak => AppTheme.textred,
    fair => AppColors.warning,
    strong => AppTheme.textingSendBtn,
  };
}

class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = PasswordStrength.of(password);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = isDark ? AppTheme.darkDivider : AppTheme.cardDivider;

    return Semantics(
      label: strength == PasswordStrength.none
          ? null
          : 'Password strength: ${strength.label}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            for (var i = 1; i <= 3; i++) ...[
              if (i > 1) const SizedBox(width: 4),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 3,
                  decoration: BoxDecoration(
                    color: i <= strength.score ? strength.color : track,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
            if (strength != PasswordStrength.none) ...[
              const SizedBox(width: 10),
              Text(
                strength.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: strength.color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
