import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:textin/core/network/client.dart';
import 'package:textin/features/whispers/data_source/whispers_remote_data_source.dart';

void main() {
  late List<http.Request> requests;
  late WhispersRemoteDataSourceImpl dataSource;

  setUp(() {
    requests = [];
    dataSource = WhispersRemoteDataSourceImpl(
      BaseApiClients(
        baseUrl: 'https://api.test',
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'id': 'w1', 'createdAt': '2026-10-27T10:00:00.000Z'},
            }),
            201,
          );
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
}
