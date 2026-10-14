import 'package:flutter/material.dart';
import '../features/home/view/home_screen.dart';
import '../features/launch/presentation/pages/launch_screen.dart';
import '../features/onboarding/presentation/pages/onboarding_screen.dart';
import '../features/texting/models/conversation.dart';
import '../features/texting/presentation/pages/secret_box_pin_screen.dart';
import '../features/texting/presentation/pages/secret_box_screen.dart';
import '../features/texting/presentation/pages/texting_chat_screen.dart';
import '../features/texting/presentation/pages/texting_inbox_screen.dart';

class AppRouter {
  static const String launch = '/';
  static const String onboarding = '/onboarding';
  static const String inbox = '/inbox';
  static const String chat = '/chat';
  static const String secretBoxPin = '/secret-box-pin';
  static const String secretBox = '/secret-box';
  static const String home = '/home';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case launch:
        return MaterialPageRoute(builder: (_) => const LaunchScreen());
      case onboarding:
        return _fadeRoute(const OnboardingScreen());
      case inbox:
        return _fadeRoute(const TextingInboxScreen());
      case chat:
        final conversation = settings.arguments as Conversation;
        return MaterialPageRoute(
          builder: (_) => TextingChatScreen(conversation: conversation),
        );
      case secretBoxPin:
        return MaterialPageRoute(builder: (_) => const SecretBoxPinScreen());
      case secretBox:
        return MaterialPageRoute(builder: (_) => const SecretBoxScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      default:
        return MaterialPageRoute(builder: (_) => const TextingInboxScreen());
    }
  }

  static Route<dynamic> _fadeRoute(Widget page) => PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
