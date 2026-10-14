import 'package:flutter/material.dart';
import '../features/auth/models/registration_step.dart';
import '../features/auth/presentation/pages/age_gender_screen.dart';
import '../features/auth/presentation/pages/create_account_screen.dart';
import '../features/auth/presentation/pages/create_password_screen.dart';
import '../features/auth/presentation/pages/login_screen.dart';
import '../features/auth/presentation/pages/pick_currents_screen.dart';
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
  static const String login = '/login';
  static const String createAccount = '/sign-up/profile';
  static const String createPassword = '/sign-up/password';
  static const String ageGender = '/sign-up/about-you';
  static const String pickCurrents = '/sign-up/currents';
  static const String chat = '/chat';
  static const String secretBoxPin = '/secret-box-pin';
  static const String secretBox = '/secret-box';
  static const String home = '/home';

  static String routeForRegistrationStep(RegistrationStep? step) =>
      switch (step) {
        RegistrationStep.accountType ||
        RegistrationStep.basicInfo => createAccount,
        RegistrationStep.passwordSetup => createPassword,
        RegistrationStep.ageGender ||
        RegistrationStep.themeSelection ||
        RegistrationStep.creatorMode => ageGender,
        RegistrationStep.currents => pickCurrents,
        null => inbox,
      };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case launch:
        return MaterialPageRoute(builder: (_) => const LaunchScreen());
      case onboarding:
        return _fadeRoute(const OnboardingScreen());
      case login:
        return _fadeRoute(const LoginScreen());
      case createAccount:
        return MaterialPageRoute(builder: (_) => const CreateAccountScreen());
      case createPassword:
        return MaterialPageRoute(builder: (_) => const CreatePasswordScreen());
      case ageGender:
        return _fadeRoute(const AgeGenderScreen());
      case pickCurrents:
        return _fadeRoute(const PickCurrentsScreen());
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
