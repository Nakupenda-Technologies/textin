import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:textin/core/network/client.dart';
import 'package:textin/features/whispers/data_source/whispers_remote_data_source.dart';

void main() {
  late List<http.Request> requests;
  late WhispersRemoteDataSourceImpl dataSource;
  late http.Response Function(http.Request request) respond;

  setUp(() {
    requests = [];
    respond = (_) => http.Response(
      jsonEncode({
        'success': true,
        'data': {'id': 'w1', 'createdAt': '2026-10-27T10:00:00.000Z'},
      }),
      201,
    );
    dataSource = WhispersRemoteDataSourceImpl(
      BaseApiClients(
        baseUrl: 'https://api.test',
        client: MockClient((request) async {
          requests.add(request);
          return respond(request);
        }),
      ),
    );
  });

  test('creates a public draft whisper', () async {
    await dataSource.createWhisper(title: 'Late night talk', isPrivate: false);

    expect(requests.single.method, 'POST');
    expect(requests.single.url.path, '/whispers');
    expect(jsonDecode(requests.single.body), {
      'title': 'Late night talk',
      'visibility': 'public',
    });
  });

  test('creates a private whisper scheduled in UTC', () async {
    await dataSource.createWhisper(
      title: 'VIP Q&A',
      isPrivate: true,
      scheduledAt: DateTime.utc(2026, 10, 28, 20),
    );

    expect(jsonDecode(requests.single.body), {
      'title': 'VIP Q&A',
      'visibility': 'private',
      'scheduledAt': '2026-10-28T20:00:00.000Z',
    });
  });

  test('joining again after a stale session leaves first', () async {
    var joins = 0;
    respond = (request) {
      if (request.url.path.endsWith('/join') && joins++ == 0) {
        return http.Response(
          jsonEncode({'message': 'User has already joined this Whisper.'}),
          409,
        );
      }
      return http.Response(jsonEncode({'success': true}), 200);
    };

    await dataSource.joinWhisper('w1');

    expect(requests.map((r) => r.url.path), [
      '/whispers/w1/join',
      '/whispers/w1/leave',
      '/whispers/w1/join',
    ]);
  });

  test('reads the audio session for the room', () async {
    respond = (_) => http.Response(
      jsonEncode({
        'success': true,
        'data': {
          'roomName': 'whisper-room-w1',
          'accessToken': 'token',
          'identity': 'whisper:w1:user:me',
          'role': 'host',
          'canPublishAudio': true,
          'canSubscribe': true,
        },
      }),
      200,
    );

    final session = await dataSource.createMediaSession('w1');

    expect(requests.single.url.path, '/whispers/w1/media/session');
    expect(session.roomName, 'whisper-room-w1');
    expect(session.accessToken, 'token');
    expect(session.canPublishAudio, isTrue);
  });
}
