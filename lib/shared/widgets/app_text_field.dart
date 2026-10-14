import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.errorText,
    this.helperText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.suffixIcon,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final String? errorText;
  final String? helperText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final bool readOnly;
  final bool enabled;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  static const _radius = BorderRadius.all(Radius.circular(35));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final error = theme.colorScheme.error;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.btnborder;

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: onSurface.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          autofillHints: enabled && !readOnly ? autofillHints : null,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          enabled: enabled,
          onTap: onTap,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          autocorrect:
              !obscureText && keyboardType != TextInputType.emailAddress,
          enableSuggestions: !obscureText,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
          decoration: InputDecoration(
            constraints: const BoxConstraints(minHeight: 50),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: onSurface.withValues(alpha: 0.4),
            ),
            helperText: helperText,
            helperMaxLines: 2,
            errorText: errorText,
            errorMaxLines: 2,
            suffixIcon: suffixIcon,
            suffixIconColor: onSurface.withValues(alpha: 0.55),
            filled: true,
            fillColor: isDark ? AppTheme.darkSurface : AppTheme.surface,
            border: border(borderColor),
            enabledBorder: border(borderColor),
            disabledBorder: border(borderColor.withValues(alpha: 0.5)),
            focusedBorder: border(onSurface.withValues(alpha: 0.5), 1.2),
            errorBorder: border(error),
            focusedErrorBorder: border(error, 1.2),
          ),
        ),
      ],
    );
  }
}
