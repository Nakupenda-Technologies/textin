import 'package:flutter/material.dart';

class AppTheme {
  static const Color red = Color.fromRGBO(169, 15, 38, 1);
  static const Color redbg = Color.fromRGBO(253, 237, 239, 1);
  static const Color postbtn = Color.fromRGBO(254, 229, 230, 1);
  static const Color pinkbg = Color.fromRGBO(255, 245, 247, 1);
  static const Color pinkborder = Color.fromRGBO(249, 207, 217, 1);

  static const Color bg = Color.fromRGBO(250, 250, 250, 1);
  static const Color surface = Color.fromRGBO(255, 255, 255, 1);
  static const Color surface2 = Color(0xFFF7F7F8);
  static const Color border = Color.fromRGBO(236, 240, 245, 1);
  static const Color divider = Color.fromRGBO(241, 244, 249, 1);
  static const Color divider2 = Color.fromRGBO(207, 213, 222, 1);

  static const Color btnborder = Color.fromRGBO(208, 213, 221, 1);
  static const Color cardDivider = Color.fromRGBO(226, 232, 240, 1);

  static const Color text = Color.fromRGBO(0, 0, 0, 1);
  static const Color title = Color.fromRGBO(16, 24, 40, 1);
  static const Color datePosted = Color.fromRGBO(112, 121, 136, 1);
  static const Color textMuted = Color.fromRGBO(131, 139, 152, 1);
  static const Color iconColor = Color.fromRGBO(107, 114, 128, 1);
  static const Color content = Color.fromRGBO(55, 65, 81, 1);
  static const Color hamburger = Color.fromRGBO(20, 27, 52, 1);
  static const Color subtitle = Color.fromRGBO(31, 41, 55, 1);
  static const Color sungrey = Color.fromRGBO(148, 163, 184, 1);
  static const Color greyFill = Color.fromRGBO(229, 229, 229, 1);
  static const Color insideGrey = Color.fromRGBO(244, 244, 245, 1);

  static const Color bottomBarBg = Color(0xFFF6FEF9);
  static const Color navActive = Color(0xFF3F3F46);
  static const Color navInactive = Color(0xFF838B98);

  static const Color cardTitle = Color.fromRGBO(12, 16, 36, 1);
  static const Color iconColors = Color.fromRGBO(83, 88, 98, 1);
  static const Color header = Color.fromRGBO(30, 30, 30, 1);
  static const Color grey = Color.fromRGBO(161, 161, 170, 1);
  static const Color textred = Color.fromRGBO(234, 26, 56, 1);
  static const Color setinggray = Color.fromRGBO(107, 114, 128, 1);
  static const Color switchtheme = Color.fromRGBO(99, 106, 110, 1);
  static const Color switchgray = Color.fromRGBO(105, 105, 105, 1);
  static const Color pillRed = Color.fromRGBO(41, 3, 8, 1);

  static const Color navbusinessactive = Color.fromRGBO(122, 200, 125, 1);
  static const Color businessActiveText = Color.fromRGBO(22, 57, 23, 1);
  static const Color businessActiveBg = Color.fromRGBO(173, 239, 174, 0.4);
  static const Color businessicon = Color.fromRGBO(81, 183, 84, 1);
  static const Color businesspostbg = Color.fromRGBO(207, 213, 222, 1);
  static const Color businessbg = Color.fromRGBO(205, 253, 205, 1);
  static const Color darkBg = Color(0xFF0F1115);
  static const Color darkSurface = Color(0xFF171A21);
  static const Color darkSurface2 = Color(0xFF1D202A);
  static const Color darkBorder = Color(0xFF232632);
  static const Color darkDivider = Color(0xFF2B3040);
  static const Color darkPinkBg2 = Color.fromRGBO(255, 241, 241, 1);

  static const Color darkText = Color(0xFFF2F4F7);
  static const Color darkTitle = Color(0xFFFFFFFF);
  static const Color darkMuted = Color(0xFF9AA4B2);
  static const Color darkIcon = Color(0xFFA6ADBB);
  static const Color darkNavBg = Color(0xFF141820);

  static const Color darkRedBg = Color(0xFF2A1418);
  static const Color darkPostBtn = Color(0xFF3A1B21);
  static const Color darkPinkBg = Color(0xFF221418);
  static const Color darkPinkBorder = Color(0xFF3A2228);
  static const Color grayBg = Color(0xffE5E7EB);
  static const Color chatAreaBg = Color(0xFFF1F1F1);

  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: red,
      onPrimary: Colors.white,
      secondary: red,
      onSecondary: Colors.white,
      error: red,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
    ),
    dividerColor: border,
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      centerTitle: true,
      foregroundColor: text,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: textMuted,
      textColor: text,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bottomBarBg,
      selectedItemColor: navActive,
      unselectedItemColor: navInactive,
    ),
    textTheme: const TextTheme(
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      bodyMedium: TextStyle(fontSize: 14, color: text),
      bodySmall: TextStyle(fontSize: 12, color: textMuted),
    ),
    iconTheme: const IconThemeData(color: textMuted),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface2,
      hintStyle: const TextStyle(color: textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: red),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return red;
        return switchtheme.withValues(alpha: 0.55);
      }),
      thumbColor: WidgetStateProperty.all(surface),
    ),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,

    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: red,
      onPrimary: Colors.white,
      secondary: red,
      onSecondary: Colors.white,
      error: red,
      onError: Colors.white,
      surface: darkSurface,
      onSurface: darkText,
    ),

    dividerColor: darkBorder,

    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      elevation: 0,
      centerTitle: true,
      foregroundColor: darkTitle,
      surfaceTintColor: Colors.transparent,
    ),

    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: darkBorder),
      ),
    ),

    listTileTheme: ListTileThemeData(
      iconColor: darkIcon,
      textColor: darkText,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkNavBg,
      selectedItemColor: darkText,
      unselectedItemColor: darkMuted,
    ),

    textTheme: const TextTheme(
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
      bodyMedium: TextStyle(fontSize: 14, color: darkText),
      bodySmall: TextStyle(fontSize: 12, color: darkMuted),
    ),

    iconTheme: const IconThemeData(color: darkIcon),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface2,
      hintStyle: const TextStyle(color: darkMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: red),
      ),
    ),

    dividerTheme: const DividerThemeData(
      thickness: 1,
      space: 1,
      color: darkDivider,
    ),

    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return red;
        return darkBorder;
      }),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        return darkText;
      }),
    ),
  );

  // ── Texting / Messaging feature ──────────────────────────────────────────
  static const Color textingSentBubble = Color(0xFFADEFAE);
  static const Color textingReceivedBubble = Color(0xFFFFFFFF);
  static const Color textingVoiceBubbleReceived = Color(0xFF3A3A3C);
  static const Color textingVoiceBubbleSent = Color(0xFFADEFAE);
  static const Color textingSecretInboxBg = Color(0xFFFFF0F0);
  static const Color textingSecretInboxBorder = Color(0xFFFFCDD2);

  static const Color textingTagRomanticBg = Color(0xFFFF3D6D);
  static const Color textingTagRomanticReceivedBg = Color(0xFFF9CFD9);
  static const Color textingTagProfessionalBg = Color(0xFFADEFAE);
  static const Color textingTagProfessionalFg = Color(0xFF163917);
  static const Color textingTagProfessionalReceivedBorder = Color(0xFFDDDEE2);
  static const Color textingTagChillBg = Color(0xFFDCEAF5);
  static const Color textingTagChillSentBorder = Color(0xFFB6CCDD);
  static const Color textingTagChillFg = Color(0xFF1E2A36);
  static const Color textingTagChillReceivedBg = Color(0x80E8F2FA);
  static const Color textingTagChillReceivedBorder = Color(0xFFDCEAF5);
  static const Color textingTagExcitedBg = Color(0xFFFFE2C6);
  static const Color textingTagExcitedFg = Color(0xFF3D240F);
  static const Color textingTagExcitedReceivedBg = Color(0x80DBD8D9);
  static const Color excitingColor = Color(0xFFFFDED2);

  static const Color textingDateChipBg = Color(0xFFE5E7EB);
  static const Color textingDateChipFg = Color(0xFF6B7280);
  static const Color textingInputBg = Color(0xFFF3F4F6);
  static const Color textingSendBtn = Color(0xFF51B754);
  static const Color textingOnlineDot = Color(0xFF22C55E);
  static const Color textingFilterActiveBg = red;
  static const Color textingFilterActiveFg = Color(0xFF0A0A0B);
  static const Color textingFilterInactiveBg = Colors.transparent;
  static const Color textingFilterInactiveFg = Color.fromARGB(255, 5, 5, 6);
  static const Color textingFireBadge = Color(0xFFFF6B35);
  static const Color textingTagRomanticBg2 = Color(0xFFFFEDE9);
  static const Color textingWaveformActive = Color(0xFFFFFFFF);
  static const Color textingWaveformInactive = Color(0xFF9E9E9E);
  static const Color textingActiveRedBorder = Color(0xFFFF7558);

  // Dark-mode counterparts for texting tokens
  static const Color darkChatAreaBg = Color(0xFF0D1117);
  static const Color darkTextingInputBg = Color(0xFF1D202A);
  static const Color darkTextingDateChipBg = Color(0xFF232632);
  static const Color darkTextingReceivedBubble = Color(0xFF1D202A);
  static const Color darkTextingFilterInactiveFg = Color(0xFFF2F4F7);
}
