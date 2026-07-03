/// The service responsible for delivering Shakura's awareness messages 
/// to the trusted contacts (friends, family, coaches).
class ShakuraAwarenessMessagingService {
  // Inject whatever messaging layer you use (SMS, email, in-app DM)
  // final MessagingService messaging;

  ShakuraAwarenessMessagingService();

  Future<void> sendAwareness({
    required String contactId,
    required String message,
  }) async {
    // TODO: wire to your real messaging system
    // await messaging.send(contactId: contactId, text: message);
  }
}
