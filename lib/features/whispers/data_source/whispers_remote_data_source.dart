import '../../../config/constants/endpoints.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/client.dart';
import '../models/live_whisper.dart';
import '../models/my_whisper.dart';
import '../models/whisper_media_session.dart';

abstract class WhispersRemoteDataSource {
  Future<List<LiveWhisper>> fetchLiveWhispers();
  Future<List<MyWhisper>> fetchMyWhispers();
  Future<void> createWhisper({
    required String title,
    required bool isPrivate,
    DateTime? scheduledAt,
  });
  Future<void> startWhisper(String id);
  Future<void> endWhisper(String id);
  Future<void> joinWhisper(String id);
  Future<void> leaveWhisper(String id);
  Future<WhisperMediaSession> createMediaSession(String id);
}

class WhispersRemoteDataSourceImpl implements WhispersRemoteDataSource {
  WhispersRemoteDataSourceImpl(this.client);

  final BaseApiClients client;

  @override
  Future<List<LiveWhisper>> fetchLiveWhispers() async {
    final dynamic response = await client.get(
      Endpoints.liveWhispers,
      queryParameters: {'limit': '50'},
    );
    return LiveWhisper.listFromResponse(response);
  }

  @override
  Future<List<MyWhisper>> fetchMyWhispers() async {
    final dynamic response = await client.get(
      Endpoints.myWhispers,
      queryParameters: {'limit': '50'},
    );
    return MyWhisper.listFromResponse(response);
  }

  @override
  Future<void> createWhisper({
    required String title,
    required bool isPrivate,
    DateTime? scheduledAt,
  }) async {
    await client.post(
      Endpoints.whispers,
      body: {
        'title': title,
        'visibility': isPrivate ? 'private' : 'public',
        'scheduledAt': ?scheduledAt?.toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<void> startWhisper(String id) async {
    await client.post(Endpoints.startWhisper(id), body: {});
  }

  @override
  Future<void> endWhisper(String id) async {
    await client.post(Endpoints.endWhisper(id), body: {});
  }

  @override
  Future<void> joinWhisper(String id) async {
    try {
      await _join(id);
    } on ServerFailure catch (e) {
      // A previous session that never left still counts as joined.
      if (e.statusCode != 409) rethrow;
      await leaveWhisper(id);
      await _join(id);
    }
  }

  Future<void> _join(String id) =>
      client.post(Endpoints.joinWhisper(id), body: {});

  @override
  Future<void> leaveWhisper(String id) async {
    await client.post(Endpoints.leaveWhisper(id), body: {});
  }

  @override
  Future<WhisperMediaSession> createMediaSession(String id) async {
    final dynamic response = await client.post(
      Endpoints.whisperMediaSession(id),
      body: {},
    );
    final session = WhisperMediaSession.fromResponse(response);
    if (session.accessToken.isEmpty || session.roomName.isEmpty) {
      throw const ServerFailure('The audio session could not be created');
    }
    return session;
  }
}
