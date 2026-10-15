import 'package:dartz/dartz.dart';
import '../../../core/errors/failure.dart';
import '../data_source/texting_remote_data_source.dart';
import '../models/api/chat_streak.dart';
import '../models/chat_customization.dart';
import '../models/conversation.dart';
import '../models/following_user.dart';
import '../models/message.dart';
import 'texting_repository.dart';

class TextingRepositoryImpl implements TextingRepository {
  TextingRepositoryImpl(this.remoteDataSource);

  final TextingRemoteDataSource remoteDataSource;

  static const _contentTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'm4a': 'audio/mp4',
    'mp3': 'audio/mpeg',
    'aac': 'audio/aac',
    'wav': 'audio/wav',
    'ogg': 'audio/ogg',
  };

  String _contentType(String filePath, {required String fallback}) =>
      _contentTypes[filePath.split('.').last.toLowerCase()] ?? fallback;

  @override
  Future<Either<Failure, List<Conversation>>> fetchRegularChats(
    int filterIndex, {
    required String myUserId,
  }) async {
    try {
      final items = await remoteDataSource.fetchRegularChats(filterIndex);
      final chats =
          items.map((i) => Conversation.fromChatItem(i, myUserId: myUserId)).toList();
      return Right(chats);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Conversation>>> fetchSecretChats({
    required String myUserId,
  }) async {
    try {
      final items = await remoteDataSource.fetchSecretChats();
      final chats =
          items.map((i) => Conversation.fromChatItem(i, myUserId: myUserId)).toList();
      return Right(chats);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> fetchMessages(
    String chatId, {
    required String myUserId,
  }) async {
    try {
      final items = await remoteDataSource.fetchMessages(chatId);
      final messages =
          items.map((m) => Message.fromApi(m, myUserId: myUserId)).toList();
      return Right(messages);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> sendTextMessage(
    String chatId,
    String text, {
    String? replyToId,
    required String myUserId,
  }) async {
    try {
      final msgApi = await remoteDataSource.sendTextMessage(
        chatId,
        text,
        replyToId: replyToId,
      );
      return Right(Message.fromApi(msgApi, myUserId: myUserId));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> sendVoiceMessage(
    String chatId,
    String filePath,
    int durationSec, {
    String? replyToId,
    required String myUserId,
  }) async {
    try {
      final mediaUrl = await remoteDataSource.uploadMedia(
        filePath,
        _contentType(filePath, fallback: 'audio/mp4'),
      );
      final msgApi = await remoteDataSource.sendVoiceMessage(
        chatId,
        mediaUrl,
        durationSec,
        replyToId: replyToId,
      );
      return Right(Message.fromApi(msgApi, myUserId: myUserId));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> sendImageMessage(
    String chatId,
    String filePath, {
    String? replyToId,
    required String myUserId,
  }) async {
    try {
      final mediaUrl = await remoteDataSource.uploadMedia(
        filePath,
        _contentType(filePath, fallback: 'image/jpeg'),
      );
      final msgApi = await remoteDataSource.sendImageMessage(
        chatId,
        mediaUrl,
        replyToId: replyToId,
      );
      return Right(Message.fromApi(msgApi, myUserId: myUserId));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markChatRead(String chatId) async {
    try {
      await remoteDataSource.markChatRead(chatId);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> togglePin(String chatId, bool isPinned) async {
    try {
      await remoteDataSource.togglePin(chatId, isPinned);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleSecretInbox(
    String chatId,
    bool inSecretInbox,
  ) async {
    try {
      await remoteDataSource.toggleSecretInbox(chatId, inSecretInbox);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomization(
    String chatId,
    ChatCustomization customization,
  ) async {
    try {
      await remoteDataSource.updateCustomization(
        chatId,
        customization.toJson(),
      );
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatStreak?>> fetchStreak(String chatId) async {
    try {
      final streak = await remoteDataSource.fetchStreak(chatId);
      return Right(streak);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Conversation>> startOrGetChat({
    required String otherUserId,
    required String myUserId,
  }) async {
    try {
      final item = await remoteDataSource.startOrGetChat(
        otherUserId: otherUserId,
      );
      return Right(Conversation.fromChatItem(item, myUserId: myUserId));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FollowingUser>>> fetchFollowingUsers(
    String username,
  ) async {
    try {
      final users = await remoteDataSource.fetchFollowingUsers(username);
      return Right(users);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
