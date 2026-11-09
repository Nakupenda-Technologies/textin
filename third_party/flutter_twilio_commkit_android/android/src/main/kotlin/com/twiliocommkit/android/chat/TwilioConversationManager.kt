package com.twiliocommkit.android.chat

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import com.twiliocommkit.android.core.TwilioEventSink

/**
 * Stubbed chat manager.
 *
 * The upstream plugin depends on com.twilio:conversations-android:2.1.2,
 * a version that was never published to any public Maven repository, so the
 * original implementation cannot compile. This app only uses the Twilio
 * Video feature (whisper live audio rooms); the chat method-channel calls
 * respond with CHAT_UNSUPPORTED instead.
 */
class TwilioConversationManager(
    @Suppress("UNUSED_PARAMETER") context: Context,
    @Suppress("UNUSED_PARAMETER") conversationEventSink: TwilioEventSink,
    @Suppress("UNUSED_PARAMETER") coroutineScope: CoroutineScope,
) {

    private fun unsupported(result: MethodChannel.Result) {
        result.error(
            "CHAT_UNSUPPORTED",
            "Twilio Conversations is not bundled in this build.",
            null,
        )
    }

    fun initConversations(call: MethodCall, result: MethodChannel.Result) = unsupported(result)

    fun updateToken(call: MethodCall, result: MethodChannel.Result) = unsupported(result)

    fun getConversations(call: MethodCall, result: MethodChannel.Result) = unsupported(result)

    fun getMessages(call: MethodCall, result: MethodChannel.Result) = unsupported(result)

    fun getUnreadCount(call: MethodCall, result: MethodChannel.Result) = unsupported(result)

    fun subscribeToConversation(call: MethodCall, result: MethodChannel.Result) = unsupported(result)

    fun setLastReadMessageIndex(call: MethodCall, result: MethodChannel.Result) = unsupported(result)

    fun sendMessage(call: MethodCall, result: MethodChannel.Result) = unsupported(result)

    fun dispose() {}
}
