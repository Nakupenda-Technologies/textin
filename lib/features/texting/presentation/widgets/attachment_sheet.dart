import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

enum AttachmentOption {
  gallery('Photo library', Icons.photo_library_outlined),
  camera('Camera', Icons.photo_camera_outlined),
  audio('Audio', Icons.audiotrack_outlined);

  const AttachmentOption(this.label, this.icon);

  final String label;
  final IconData icon;
}

class AttachmentSheet extends StatelessWidget {
  const AttachmentSheet({super.key});

  static Future<AttachmentOption?> show(BuildContext context) {
    return showModalBottomSheet<AttachmentOption>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AttachmentSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.grayBg,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            for (final option in AttachmentOption.values)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: isDark
                      ? AppTheme.darkSurface2
                      : AppTheme.insideGrey,
                  child: Icon(
                    option.icon,
                    size: 20,
                    color: AppTheme.textingSendBtn,
                  ),
                ),
                title: Text(
                  option.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
  }
}
