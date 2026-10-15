import 'package:flutter/material.dart';
import '../features/auth/models/registration_step.dart';
import '../features/auth/presentation/pages/age_gender_screen.dart';
import '../features/auth/presentation/pages/create_account_screen.dart';
import '../features/auth/presentation/pages/create_password_screen.dart';
import '../features/auth/presentation/pages/forgot_password_screen.dart';
import '../features/auth/presentation/pages/login_screen.dart';
import '../features/auth/presentation/pages/new_password_screen.dart';
import '../features/auth/presentation/pages/pick_currents_screen.dart';
import '../features/auth/presentation/pages/reset_code_screen.dart';
import '../features/home/view/home_screen.dart';
import '../features/launch/presentation/pages/launch_screen.dart';
import '../features/navigation/presentation/pages/main_navigation_screen.dart';
import '../features/onboarding/presentation/pages/onboarding_screen.dart';
import '../features/texting/models/conversation.dart';
import '../features/texting/presentation/pages/secret_box_pin_screen.dart';
import '../features/texting/presentation/pages/secret_box_screen.dart';
import '../features/texting/presentation/pages/texting_chat_screen.dart';

class AppRouter {
  static const String launch = '/';
  static const String onboarding = '/onboarding';
  static const String inbox = '/inbox';
  static const String login = '/login';
  static const String createAccount = '/sign-up/profile';
  static const String createPassword = '/sign-up/password';
  static const String ageGender = '/sign-up/about-you';
  static const String pickCurrents = '/sign-up/currents';
  static const String forgotPassword = '/forgot-password';
  static const String resetCode = '/forgot-password/code';
  static const String newPassword = '/forgot-password/new-password';
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
      case forgotPassword:
        final email = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => ForgotPasswordScreen(
            initialEmail: email is String ? email : null,
          ),
        );
      case resetCode:
        return MaterialPageRoute(builder: (_) => const ResetCodeScreen());
      case newPassword:
        return MaterialPageRoute(builder: (_) => const NewPasswordScreen());
      case inbox:
        return _fadeRoute(const MainNavigationScreen());
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
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
    }
  }

  static Route<dynamic> _fadeRoute(Widget page) => PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
