import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/storage/shared_pref_keys.dart';
import '../../../../core/storage/shared_preferences_store.dart';
import '../../../../router/app_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../widgets/holding_hands_scene.dart';
import '../widgets/love_potion_scene.dart';
import '../widgets/secure_scene.dart';

typedef _Slide = ({Widget scene, String title, String subtitle});

TextStyle _font(
  String family, {
  required double size,
  required double weight,
  required Color color,
  double? height,
}) => TextStyle(
  fontFamily: family,
  fontSize: size,
  fontVariations: [FontVariation.weight(weight)],
  color: color,
  height: height,
);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const List<_Slide> _slides = [
    (
      scene: HoldingHandsScene(),
      title: 'Talk closer',
      subtitle: 'Private conversations with the people who matter most.',
    ),
    (
      scene: SecureScene(),
      title: 'Keep it secret',
      subtitle: 'Lock personal chats away behind your Secret Box PIN.',
    ),
    (
      scene: LovePotionScene(),
      title: 'Keep the spark',
      subtitle: 'Chat every day to grow your streaks and stay connected.',
    ),
  ];

  bool get _isLastPage => _page == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await SharedPreferencesStore.setBool(SharedPrefKeys.onboardingSeen, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRouter.inbox);
  }

  void _next() {
    if (_isLastPage) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppTheme.darkMuted : AppTheme.textMuted;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    opacity: _isLastPage ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: _isLastPage ? null : _finish,
                      style: TextButton.styleFrom(foregroundColor: muted),
                      child: Text(
                        'Skip',
                        style: _font(
                          'Syne',
                          size: 14,
                          weight: 600,
                          color: muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) =>
                      _SlideView(slide: _slides[index]),
                ),
              ),
              const SizedBox(height: 32),
              _PageDots(count: _slides.length, active: _page),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.textred,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: Text(
                    _isLastPage ? 'Get started' : 'Next',
                    style: _font(
                      'Syne',
                      size: 16,
                      weight: 600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final diameter = min(
                min(constraints.maxWidth, constraints.maxHeight),
                360.0,
              );
              return Center(
                child: ClipOval(
                  child: Container(
                    width: diameter,
                    height: diameter,
                    color: isDark ? AppTheme.darkPinkBg2 : AppTheme.pinkbg,
                    child: slide.scene,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 36),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: _font(
            'Urbanist',
            size: 32,
            weight: 600,
            height: 1.15,
            color: isDark ? AppTheme.darkTitle : AppTheme.text,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: _font(
              'Urbanist',
              size: 16,
              weight: 500,
              height: 1.5,
              color: isDark ? AppTheme.darkMuted : AppTheme.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == active
                  ? AppTheme.textred
                  : (isDark ? AppTheme.darkDivider : AppTheme.greyFill),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
