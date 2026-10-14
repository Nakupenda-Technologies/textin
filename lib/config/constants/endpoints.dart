class Endpoints {
  Endpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';
  static const String me = '/users/me';
  static const String validateUsername = '/users/validate-username';
  static const String currents = '/currents';

  // Registration process
  static const String processTrackerSetup = '/process-tracker/setup';
  static String processTracker(String processId) =>
      '/process-tracker/$processId';
  static String processTrackerStep(String processId) =>
      '/process-tracker/$processId/step';
  static String processTrackerComplete(String processId) =>
      '/process-tracker/$processId/complete';

  // Messaging / Chats
  static const String startOrGetChat = '/messaging/chats';
  static String chatMessages(String chatId) =>
      '/messaging/chats/$chatId/messages';
  static String markChatRead(String chatId) => '/messaging/chats/$chatId/read';
  static String chatSecretInbox(String chatId) =>
      '/messaging/chats/$chatId/secret-inbox';
  static String chatPin(String chatId) => '/messaging/chats/$chatId/pin';
  static String chatBoundary(String chatId) =>
      '/messaging/chats/$chatId/boundary';
  static String chatStreak(String chatId) => '/messaging/chats/$chatId/streak';

  // Users & Contacts
  static String userFollowing(String username) => '/users/$username/following';

  // Media upload
  static const String mediaUpload = '/media/upload/messaging';
}
