import 'package:dartz/dartz.dart';
import '../../../core/errors/failure.dart';
import '../models/chat_customization.dart';
import '../models/conversation.dart';
import '../models/following_user.dart';
import '../models/message.dart';
import '../models/api/chat_streak.dart';

abstract class TextingRepository {
  Future<Either<Failure, List<Conversation>>> fetchRegularChats(
    int filterIndex, {
    required String myUserId,
  });

  Future<Either<Failure, List<Conversation>>> fetchSecretChats({
    required String myUserId,
  });

  Future<Either<Failure, List<Message>>> fetchMessages(
    String chatId, {
    required String myUserId,
  });

  Future<Either<Failure, Message>> sendTextMessage(
    String chatId,
    String text, {
    String? replyToId,
    required String myUserId,
  });

  Future<Either<Failure, Message>> sendVoiceMessage(
    String chatId,
    String filePath,
    int durationSec, {
    String? replyToId,
    required String myUserId,
  });

  Future<Either<Failure, Message>> sendImageMessage(
    String chatId,
    String filePath, {
    String? replyToId,
    required String myUserId,
  });

  Future<Either<Failure, void>> markChatRead(String chatId);

  Future<Either<Failure, void>> togglePin(String chatId, bool isPinned);

  Future<Either<Failure, void>> toggleSecretInbox(
    String chatId,
    bool inSecretInbox,
  );

  Future<Either<Failure, void>> updateCustomization(
    String chatId,
    ChatCustomization customization,
  );

  Future<Either<Failure, ChatStreak?>> fetchStreak(String chatId);

  Future<Either<Failure, Conversation>> startOrGetChat({
    required String otherUserId,
    required String myUserId,
  });

  Future<Either<Failure, List<FollowingUser>>> fetchFollowingUsers(
    String username,
  );

  Future<Either<Failure, List<FollowingUser>>> fetchSuggestedUsers();
}
