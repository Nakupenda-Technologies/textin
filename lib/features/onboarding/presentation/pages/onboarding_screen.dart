import 'package:flutter/material.dart';

import '../../../../core/storage/shared_pref_keys.dart';
import '../../../../core/storage/shared_preferences_store.dart';
import '../../../../router/app_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../widgets/holding_hands_scene.dart';
import '../widgets/love_potion_scene.dart';
import '../widgets/secure_scene.dart';

typedef _Slide = ({
  Widget scene,
  String greeting,
  String emoji,
  String title,
  String subtitle,
});

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
      greeting: 'Hey there!',
      emoji: '👋',
      title: 'Talk closer',
      subtitle:
          'Private conversations with the people who matter, all in one place.',
    ),
    (
      scene: SecureScene(),
      greeting: 'Your space',
      emoji: '🔒',
      title: 'Keep it secret',
      subtitle:
          'Lock personal chats in your Secret Box. Only your PIN opens it.',
    ),
    (
      scene: LovePotionScene(),
      greeting: 'Keep it lit',
      emoji: '🔥',
      title: 'Spark streaks',
      subtitle:
          'Chat every day to grow your streaks and keep the connection alive.',
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
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.chatAreaBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              _Header(showSkip: !_isLastPage, onSkip: _finish),
              const SizedBox(height: 24),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) =>
                      _SlideView(slide: _slides[index]),
                ),
              ),
              const SizedBox(height: 24),
              _PageDots(count: _slides.length, active: _page),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.textred,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(_isLastPage ? 'Get started' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.showSkip, required this.onSkip});

  final bool showSkip;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Image.asset(
            isDark
                ? 'assets/images/textin_wordmark_dark.png'
                : 'assets/images/textin_wordmark.png',
            height: 30,
          ),
          const Spacer(),
          if (showSkip)
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? AppTheme.darkMuted
                    : AppTheme.textMuted,
              ),
              child: const Text('Skip'),
            ),
        ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkPinkBg2 : AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: slide.scene,
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Text(
              slide.greeting,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppTheme.darkMuted : AppTheme.content,
              ),
            ),
            const SizedBox(width: 8),
            _EmojiBubble(emoji: slide.emoji),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          slide.title,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            height: 1.1,
            color: isDark ? AppTheme.darkTitle : AppTheme.text,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          slide.subtitle,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: isDark ? AppTheme.darkMuted : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _EmojiBubble extends StatelessWidget {
  const _EmojiBubble({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.btnborder,
        ),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 16)),
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
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == active ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == active
                  ? AppTheme.textred
                  : (isDark ? AppTheme.darkDivider : AppTheme.pinkborder),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
