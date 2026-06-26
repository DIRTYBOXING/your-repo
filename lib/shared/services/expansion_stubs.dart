/// Safe expansion stubs — throw UnimplementedError with clear messages
/// so callers fail explicitly instead of silently doing nothing.
library;

class _StubException implements Exception {
  final String service;
  final String method;
  _StubException(this.service, this.method);
  @override
  String toString() =>
      '$service.$method is not yet implemented. '
      'This feature is coming soon.';
}

/// Stub for Livestream/PPV events
class LivestreamService {
  Future<void> startStream() async {
    throw _StubException('LivestreamService', 'startStream');
  }

  Future<void> joinStream(String eventId) async {
    throw _StubException('LivestreamService', 'joinStream');
  }
}

/// Stub for Polls/Voting
class PollsService {
  Future<void> createPoll() async {
    throw _StubException('PollsService', 'createPoll');
  }

  Future<void> vote(String pollId, int option) async {
    throw _StubException('PollsService', 'vote');
  }
}

/// Stub for Event RSVP/Attendance
class EventRSVPService {
  Future<void> rsvpToEvent(String eventId) async {
    throw _StubException('EventRSVPService', 'rsvpToEvent');
  }

  Future<List<String>> getAttendees(String eventId) async {
    throw _StubException('EventRSVPService', 'getAttendees');
  }
}

/// Stub for CRM/Promoter tools
class CRMIntegrationService {
  Future<void> syncContacts() async {
    throw _StubException('CRMIntegrationService', 'syncContacts');
  }
}

/// Stub for Webhooks/Automation
class WebhookService {
  Future<void> registerWebhook(String url) async {
    throw _StubException('WebhookService', 'registerWebhook');
  }

  Future<void> triggerWebhook(String event) async {
    throw _StubException('WebhookService', 'triggerWebhook');
  }
}

/// Stub for Media Uploads
class MediaUploadService {
  Future<void> uploadMedia(String filePath) async {
    throw _StubException('MediaUploadService', 'uploadMedia');
  }
}

/// Stub for Community Moderation
class CommunityModerationService {
  Future<void> reportContent(String contentId) async {
    throw _StubException('CommunityModerationService', 'reportContent');
  }

  Future<void> banUser(String userId) async {
    throw _StubException('CommunityModerationService', 'banUser');
  }
}
