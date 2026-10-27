import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/texting/models/following_user.dart';
import 'package:textin/features/texting/presentation/widgets/new_chat_sheet.dart';
import 'package:textin/features/texting/repository/texting_repository.dart';

const _ada = FollowingUser(id: 'u2', username: 'ada', displayName: 'Ada Obi');
const _ben = FollowingUser(id: 'u3', username: 'ben', displayName: 'Ben Eze');

class _FakeTextingRepository implements TextingRepository {
  _FakeTextingRepository({
    this.following = const [],
    this.suggested = const [],
  });

  List<FollowingUser> following;
  List<FollowingUser> suggested;
  Either<Failure, void> followResult = const Right(null);
  final followed = <String>[];

  @override
  Future<Either<Failure, List<FollowingUser>>> fetchFollowingUsers(
    String username,
  ) async => Right(following);

  @override
  Future<Either<Failure, List<FollowingUser>>> fetchSuggestedUsers() async =>
      Right(suggested);

  @override
  Future<Either<Failure, void>> followUser(String username) async {
    followed.add(username);
    return followResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final selected = <FollowingUser>[];
  Completer<void> chatOpened = Completer();

  setUp(() {
    selected.clear();
    chatOpened = Completer()..complete();
  });

  Future<void> pumpSheet(
    WidgetTester tester,
    _FakeTextingRepository repository,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NewChatSheet(
            repository: repository,
            myUserId: 'me',
            myUsername: 'me',
            onSelectUser: (user) {
              selected.add(user);
              return chatOpened.future;
            },
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('suggests people to follow when nobody is followed yet', (
    tester,
  ) async {
    await pumpSheet(tester, _FakeTextingRepository(suggested: [_ada]));

    expect(
      find.textContaining('only chat with people you follow'),
      findsOneWidget,
    );
    expect(find.text('Suggested for you'), findsOneWidget);
    expect(find.text('Ada Obi'), findsOneWidget);
    expect(find.text('Follow'), findsOneWidget);
  });

  testWidgets('hides suggestions for people already followed', (tester) async {
    await pumpSheet(
      tester,
      _FakeTextingRepository(following: [_ada], suggested: [_ada, _ben]),
    );

    expect(find.text('Ada Obi'), findsOneWidget);
    expect(find.text('Follow'), findsOneWidget);
    expect(
      find.textContaining('only chat with people you follow'),
      findsNothing,
    );
  });

  testWidgets('following a suggestion makes them available to chat', (
    tester,
  ) async {
    final repository = _FakeTextingRepository(suggested: [_ada]);
    await pumpSheet(tester, repository);

    await tester.tap(find.text('Follow'));
    await tester.pump();

    expect(repository.followed, ['ada']);
    expect(find.text('Suggested for you'), findsNothing);
    expect(find.text('Follow'), findsNothing);

    await tester.tap(find.text('Ada Obi'));
    await tester.pump();

    expect(selected, [_ada]);
  });

  testWidgets('a failed follow keeps the suggestion', (tester) async {
    final repository = _FakeTextingRepository(suggested: [_ada])
      ..followResult = const Left(ServerFailure('Nope'));
    await pumpSheet(tester, repository);

    await tester.tap(find.text('Follow'));
    await tester.pump();

    expect(find.text('Suggested for you'), findsOneWidget);
    expect(find.text('Follow'), findsOneWidget);
  });

  testWidgets('stays open while the chat is starting', (tester) async {
    chatOpened = Completer();
    await pumpSheet(tester, _FakeTextingRepository(following: [_ada]));

    await tester.tap(find.text('Ada Obi'));
    await tester.pump();

    expect(find.text('New Conversation'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('Ada Obi'));
    expect(selected, [_ada]);

    chatOpened.complete();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
