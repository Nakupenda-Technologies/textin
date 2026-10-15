import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/di/locator.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/notifier/session_notifier.dart';
import '../../repository/settings_repository.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _bio;
  String? _newPicturePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _bio = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickPicture() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (image != null) setState(() => _newPicturePath = image.path);
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isSaving = true);

    final result = await locator<SettingsRepository>().updateProfile(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      bio: _bio.text.trim(),
      newPicturePath: _newPicturePath,
    );
    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      if (mounted) setState(() => _isSaving = false);
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }

    final refreshed = await ref.read(authRepositoryProvider).refreshUser();
    refreshed.fold(
      (_) {},
      (user) => ref.read(currentUserProvider.notifier).state = user,
    );
    messenger.showSnackBar(const SnackBar(content: Text('Profile updated')));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picture = user?.profilePicture;
    final ImageProvider? avatar = _newPicturePath != null
        ? FileImage(File(_newPicturePath!))
        : picture != null
        ? CachedNetworkImageProvider(picture)
        : null;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.chatAreaBg,
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickPicture,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: cs.onSurface.withValues(alpha: 0.10),
                      backgroundImage: avatar,
                      child: avatar == null
                          ? Icon(
                              PhosphorIconsRegular.user,
                              size: 36,
                              color: cs.onSurface,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.textred,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.surface, width: 2),
                        ),
                        child: const Icon(
                          PhosphorIconsFill.camera,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            AppTextField(
              label: 'First name',
              hintText: 'Your first name',
              controller: _firstName,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Last name',
              hintText: 'Your last name',
              controller: _lastName,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Bio',
              hintText: 'Tell people a little about you',
              controller: _bio,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(2000)],
            ),
            const SizedBox(height: 32),
            AppButton(label: 'Save', isLoading: _isSaving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
