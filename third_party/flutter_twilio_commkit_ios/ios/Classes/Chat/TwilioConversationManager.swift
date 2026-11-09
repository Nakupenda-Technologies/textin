import Flutter

/// Stubbed chat manager.
///
/// The upstream plugin depends on the TwilioConversationsClient pod at
/// `~> 2.7`, a version range that was never published to CocoaPods (trunk
/// stops at 2.2.8), so the original implementation cannot resolve. This app
/// only uses the Twilio Video feature (whisper live audio rooms); the chat
/// method-channel calls respond with CHAT_UNSUPPORTED instead.
final class TwilioConversationManager: NSObject {

    init(eventSink: TwilioEventSink) {}

    private func unsupported(_ result: @escaping FlutterResult) {
        result(FlutterError(
            code: "CHAT_UNSUPPORTED",
            message: "Twilio Conversations is not bundled in this build.",
            details: nil
        ))
    }

    func initConversations(args: [String: Any], result: @escaping FlutterResult) { unsupported(result) }

    func updateToken(args: [String: Any], result: @escaping FlutterResult) { unsupported(result) }

    func getConversations(args: [String: Any], result: @escaping FlutterResult) { unsupported(result) }

    func getMessages(args: [String: Any], result: @escaping FlutterResult) { unsupported(result) }

    func getUnreadCount(args: [String: Any], result: @escaping FlutterResult) { unsupported(result) }

    func subscribeToConversation(args: [String: Any], result: @escaping FlutterResult) { unsupported(result) }

    func setLastReadMessageIndex(args: [String: Any], result: @escaping FlutterResult) { unsupported(result) }

    func sendMessage(args: [String: Any], result: @escaping FlutterResult) { unsupported(result) }

    func dispose() {}
}
