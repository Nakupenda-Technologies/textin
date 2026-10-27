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
  static String chatCustomization(String chatId) =>
      '/messaging/chats/$chatId/customization';

  // Users & Contacts
  static String userFollowing(String username) => '/users/$username/following';
  static String followUser(String username) => '/users/$username/follow';
  static const String suggestedAccounts = '/explore/suggested-accounts';

  // Settings
  static const String settings = '/settings/me';
  static const String blockedUsers = '/settings/me/blocked';
  static const String mutedUsers = '/settings/me/muted';
  static const String emailChangeRequest = '/settings/me/account/email/request';
  static const String emailChangeConfirm = '/settings/me/account/email/confirm';
  static const String changePassword = '/settings/me/account/password';
  static const String deactivateAccount = '/settings/me/account/deactivate';
  static const String deleteAccount = '/settings/me/account/delete';
  static String userById(String userId) => '/users/id/$userId';
  static const String profilePictureUpload = '/media/upload/profiles';

  // Whispers
  static const String whispers = '/whispers';
  static const String liveWhispers = '/whispers/live';
  static const String myWhispers = '/whispers/mine';
  static String startWhisper(String id) => '/whispers/$id/start';
  static String endWhisper(String id) => '/whispers/$id/end';
  static String joinWhisper(String id) => '/whispers/$id/join';
  static String leaveWhisper(String id) => '/whispers/$id/leave';
  static String whisperMediaSession(String id) => '/whispers/$id/media/session';

  // Media upload
  static const String mediaUpload = '/media/upload/messaging';
}
