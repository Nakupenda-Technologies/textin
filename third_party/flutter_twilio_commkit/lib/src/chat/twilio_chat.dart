import 'dart:async';
import 'package:flutter/services.dart';

/// The main entry-point for Twilio Conversations/Chat functionality.
///
/// Exposes a simple, headless API over the native Twilio Conversations SDK.
///
/// ## Unread-count design note
/// [getUnReadMsgCount] derives the unread count from `lastMessageIndex` and
/// `lastConsumedMessageIndex` – both of which are **local** properties cached
/// on the native Conversation object after initial sync.  This avoids the
/// async `getUnconsumedMessagesCount()` call that can return `null` while the
/// conversation is re-synchronising (e.g. after navigating back to the list),
/// which caused the "unread marker disappears on re-entry" bug.
class TwilioConversationSdk {
  static const MethodChannel _channel =
      MethodChannel('com.twiliocommkit/methods');
  static const EventChannel _conversationEventChannel =
      EventChannel('com.twiliocommkit/conversation_events');

  /// Broadcast stream of raw conversation events (messageAdded, messageUpdated,
  /// typingStarted, typingEnded).
  late final Stream<Map<Object?, Object?>> onMessageReceived =
      _conversationEventChannel
          .receiveBroadcastStream()
          .where((e) => e is Map)
          .map((e) => Map<Object?, Object?>.from(e as Map))
          .asBroadcastStream();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Initialises the Twilio Conversations client with an [accessToken].
  ///
  /// Must be called once before any other method.
  Future<void> initConversations({required String accessToken}) async {
    await _channel.invokeMethod<void>('initConversations', {
      'accessToken': accessToken,
    });
  }

  /// Updates the Conversations client access token (e.g. on expiry).
  Future<void> updateConversationsToken({required String accessToken}) async {
    await _channel.invokeMethod<void>('updateConversationsToken', {
      'accessToken': accessToken,
    });
  }

  // ── Conversations ──────────────────────────────────────────────────────────

  /// Returns the list of conversations the current user is subscribed to.
  ///
  /// Each item is a `Map<Object?, Object?>` with the following keys:
  /// - `sid` – conversation SID
  /// - `conversationName` – friendly name
  /// - `lastMessageDate` – ISO-8601 date string
  /// - `lastMessageIndex` – index of the most-recent message (int)
  /// - `lastConsumedMessageIndex` – last message read by the local participant (int)
  /// - `unreadCount` – **pre-computed** unread count (int); avoids the
  ///   async-sync race that plagued [getUnReadMsgCount] when navigating back
  /// - `participantsCount` – number of participants (int)
  /// - `isGroup` – whether more than 2 participants
  /// - `createdBy` – identity string of the creator
  /// - `dateCreated` – ISO-8601 creation date
  Future<List<dynamic>?> getConversations() async {
    return _channel.invokeListMethod<dynamic>('getConversations');
  }

  // ── Messages ───────────────────────────────────────────────────────────────

  /// Returns the last [count] messages for [conversationId].
  ///
  /// Each item is a `Map<Object?, Object?>` with keys:
  /// `sid`, `author`, `body`, `dateCreated`, `index`, `conversationSid`.
  ///
  /// **Important:** Calling this method does NOT advance the read index.
  /// Call [setLastReadMessageIndex] explicitly when the user views a message.
  Future<List<dynamic>?> getMessages({
    required String conversationId,
    int count = 50,
  }) async {
    return _channel.invokeListMethod<dynamic>('getConversationMessages', {
      'conversationSid': conversationId,
      'count': count,
    });
  }

  // ── Unread count ───────────────────────────────────────────────────────────

  /// Returns a single-element list containing an unread-count map for
  /// [conversationId].
  ///
  /// The returned map has keys `sid` and `unReadCount`.
  ///
  /// ### Fix for "unread disappears on re-entry"
  /// This method now computes the unread count from `lastMessageIndex` –
  /// `lastConsumedMessageIndex` on the native side.  Both values are **local**
  /// properties on the cached Conversation object; they do not require a
  /// round-trip to the Twilio service, so they are always accurate even while
  /// a conversation is re-synchronising after navigation.
  ///
  /// Previously the implementation called `getUnconsumedMessagesCount()` which
  /// is async and returns `null` before the conversation has fully re-synced,
  /// causing the `?? 0` fallback to wrongly hide the unread indicator.
  Future<List<dynamic>?> getUnReadMsgCount({
    required String conversationId,
  }) async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'getConversationUnreadCount',
      {'conversationSid': conversationId},
    );
    if (result == null) return null;
    return [result];
  }

  // ── Subscriptions ──────────────────────────────────────────────────────────

  /// Subscribes to message-update events for [conversationSid].
  ///
  /// After subscribing, new messages and typing indicators will be emitted on
  /// [onMessageReceived].  You only need to call this once per conversation
  /// SID; duplicate calls are safely ignored.
  Future<void> subscribeToMessageUpdate({required String conversationSid}) async {
    await _channel.invokeMethod<void>('subscribeToConversation', {
      'conversationSid': conversationSid,
    });
  }

  /// Advances the last-read message index for [conversationSid].
  ///
  /// Call this when the user opens a conversation to clear the unread badge.
  /// Passing the highest visible `message.index` is sufficient.
  Future<void> setLastReadMessageIndex({
    required String conversationSid,
    required int index,
  }) async {
    await _channel.invokeMethod<void>('setLastReadMessageIndex', {
      'conversationSid': conversationSid,
      'index': index,
    });
  }

  // ── Sending ────────────────────────────────────────────────────────────────

  /// Sends a text [body] message to [conversationSid].
  ///
  /// Returns the newly created message map on success.
  Future<Map<Object?, Object?>?> sendMessage({
    required String conversationSid,
    required String body,
  }) async {
    return _channel.invokeMethod<Map<Object?, Object?>>('sendConversationMessage', {
      'conversationSid': conversationSid,
      'body': body,
    });
  }
}
