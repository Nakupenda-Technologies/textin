class Endpoints {
  Endpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';

  // Messaging / Chats
  static const String startOrGetChat = '/messaging/chats';
  static String chatMessages(String chatId) => '/messaging/chats/$chatId/messages';
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
