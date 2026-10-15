import 'package:flutter/material.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Textin',
      image: true,
      child: Image.asset(
        isDark
            ? 'assets/images/textin_wordmark_dark.png'
            : 'assets/images/textin_wordmark.png',
        height: 30,
        excludeFromSemantics: true,
      ),
    );
  }
}
