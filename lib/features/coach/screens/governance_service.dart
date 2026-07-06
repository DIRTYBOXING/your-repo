import '../../../shared/models/user_model.dart';
import '../../../shared/services/auth_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC GOVERNANCE ENGINE
/// Evaluates capabilities based on the user's role.
/// Roles: fan, fighter, coach, gym_owner, promoter, official, medical, sponsor, admin
/// ═══════════════════════════════════════════════════════════════════════════
class GovernanceService {
  final AuthService _authService;

  GovernanceService(this._authService);

  UserRole? get _currentRole => _authService.userModel?.role;

  // ─── CONTENT CAPABILITIES ───

  /// Can the user post to the global Social Feed?
  bool get canCreateFeedPost {
    final role = _currentRole;
    if (role == null) return false;
    // Fans cannot post, everyone else can.
    return role != UserRole.fan;
  }

  /// Can the user create and publish an Event?
  bool get canCreateEvent {
    final role = _currentRole;
    return role == UserRole.promoter || role == UserRole.admin;
  }

  /// Can the user gate an event behind a PPV paywall?
  bool get canCreatePpv {
    final role = _currentRole;
    return role == UserRole.promoter || role == UserRole.admin;
  }

  // ─── MODERATION CAPABILITIES ───

  /// Can the user suspend accounts or remove content?
  bool get canModerateContent {
    return _currentRole == UserRole.admin;
  }

  // ─── FINANCIAL CAPABILITIES ───

  /// Can the user view and settle payouts?
  bool get canSettlePayouts {
    final role = _currentRole;
    return role == UserRole.promoter || role == UserRole.admin;
  }
}
