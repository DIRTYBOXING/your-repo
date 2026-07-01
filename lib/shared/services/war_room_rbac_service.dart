import 'package:flutter/foundation.dart';
import '../models/kanban_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// WAR ROOM RBAC SERVICE — Role-based access, 2FA gating, approval flows
/// Roles: Founder Admin, Ops Lead, Safety Officer, Promoter Manager, Read-Only
/// ═══════════════════════════════════════════════════════════════════════════

class WarRoomUser {
  final String uid;
  final String displayName;
  final WarRoomRole role;
  final bool twoFactorEnabled;
  final DateTime lastLogin;

  const WarRoomUser({
    required this.uid,
    required this.displayName,
    required this.role,
    this.twoFactorEnabled = false,
    required this.lastLogin,
  });
}

class ApprovalRequest {
  final String id;
  final String actionId;
  final String requestedBy;
  final String? approvedBy;
  final String? secondApprover;
  final bool requiresSecondApproval;
  final String status; // pending, approved, rejected
  final String reason;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const ApprovalRequest({
    required this.id,
    required this.actionId,
    required this.requestedBy,
    this.approvedBy,
    this.secondApprover,
    this.requiresSecondApproval = false,
    this.status = 'pending',
    this.reason = '',
    required this.createdAt,
    this.resolvedAt,
  });
}

class WarRoomRbacService with ChangeNotifier {
  static final WarRoomRbacService _instance = WarRoomRbacService._();
  factory WarRoomRbacService() => _instance;
  WarRoomRbacService._();

  WarRoomUser? _currentUser;
  final List<WarRoomUser> _users = [];
  final List<ApprovalRequest> _approvals = [];
  final Map<WarRoomRole, RolePermission> _permissions = {};
  bool _initialized = false;

  WarRoomUser? get currentUser => _currentUser;
  List<WarRoomUser> get users => List.unmodifiable(_users);
  List<ApprovalRequest> get pendingApprovals =>
      _approvals.where((a) => a.status == 'pending').toList();
  List<ApprovalRequest> get allApprovals => List.unmodifiable(_approvals);
  bool get initialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    _seedPermissions();
    _seedUsers();
    _initialized = true;
    notifyListeners();
  }

  // ─── Permission Checks ─────────────────────────────────────────────────

  bool canDeploy([WarRoomRole? role]) =>
      _perm(role ?? _currentUser?.role).canDeploy;

  bool canRollback([WarRoomRole? role]) =>
      _perm(role ?? _currentUser?.role).canRollback;

  bool canPausePpv([WarRoomRole? role]) =>
      _perm(role ?? _currentUser?.role).canPausePPV;

  bool canApprovePayouts([WarRoomRole? role]) =>
      _perm(role ?? _currentUser?.role).canApprovePayouts;

  bool canManageCards([WarRoomRole? role]) =>
      _perm(role ?? _currentUser?.role).canManageCards;

  bool canViewAuditLogs([WarRoomRole? role]) =>
      _perm(role ?? _currentUser?.role).canViewAuditLogs;

  bool canManageSafety([WarRoomRole? role]) =>
      _perm(role ?? _currentUser?.role).canManageSafety;

  bool canEditRunbooks([WarRoomRole? role]) =>
      _perm(role ?? _currentUser?.role).canEditRunbooks;

  bool requiresSecondApprover([WarRoomRole? role]) =>
      _perm(role ?? _currentUser?.role).requiresSecondApprover;

  RolePermission _perm(WarRoomRole? role) =>
      _permissions[role] ??
      const RolePermission(role: WarRoomRole.readOnlyAuditor);

  // ─── Auth ──────────────────────────────────────────────────────────────

  void setCurrentUser(WarRoomUser user) {
    _currentUser = user;
    notifyListeners();
  }

  void switchRole(WarRoomRole role) {
    if (_currentUser == null) return;
    _currentUser = WarRoomUser(
      uid: _currentUser!.uid,
      displayName: _currentUser!.displayName,
      role: role,
      twoFactorEnabled: _currentUser!.twoFactorEnabled,
      lastLogin: _currentUser!.lastLogin,
    );
    notifyListeners();
  }

  // ─── 2FA Gate ──────────────────────────────────────────────────────────

  Future<bool> verify2FA() async {
    // Stub: In production, prompt for OTP/biometric
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  // ─── Approval Flow ─────────────────────────────────────────────────────

  ApprovalRequest requestApproval({
    required String actionId,
    required String requestedBy,
    required String reason,
    bool needsSecond = false,
  }) {
    final req = ApprovalRequest(
      id: 'apr_${DateTime.now().millisecondsSinceEpoch}',
      actionId: actionId,
      requestedBy: requestedBy,
      requiresSecondApproval: needsSecond,
      reason: reason,
      createdAt: DateTime.now(),
    );
    _approvals.insert(0, req);
    notifyListeners();
    return req;
  }

  bool approveRequest(String approvalId, String approverUid) {
    final idx = _approvals.indexWhere((a) => a.id == approvalId);
    if (idx == -1) return false;
    final req = _approvals[idx];
    if (req.status != 'pending') return false;

    _approvals[idx] = ApprovalRequest(
      id: req.id,
      actionId: req.actionId,
      requestedBy: req.requestedBy,
      approvedBy: approverUid,
      secondApprover: req.secondApprover,
      requiresSecondApproval: req.requiresSecondApproval,
      status: 'approved',
      reason: req.reason,
      createdAt: req.createdAt,
      resolvedAt: DateTime.now(),
    );
    notifyListeners();
    return true;
  }

  bool rejectRequest(String approvalId, String reason) {
    final idx = _approvals.indexWhere((a) => a.id == approvalId);
    if (idx == -1) return false;

    final req = _approvals[idx];
    _approvals[idx] = ApprovalRequest(
      id: req.id,
      actionId: req.actionId,
      requestedBy: req.requestedBy,
      status: 'rejected',
      reason: reason,
      requiresSecondApproval: req.requiresSecondApproval,
      createdAt: req.createdAt,
      resolvedAt: DateTime.now(),
    );
    notifyListeners();
    return true;
  }

  // ─── Seed ──────────────────────────────────────────────────────────────

  void _seedPermissions() {
    _permissions.addAll({
      WarRoomRole.founderAdmin: const RolePermission(
        role: WarRoomRole.founderAdmin,
        canDeploy: true,
        canRollback: true,
        canPausePPV: true,
        canApprovePayouts: true,
        canManageCards: true,
        canViewAuditLogs: true,
        canManageSafety: true,
        canEditRunbooks: true,
      ),
      WarRoomRole.opsLead: const RolePermission(
        role: WarRoomRole.opsLead,
        canDeploy: true,
        canRollback: true,
        canPausePPV: true,
        canManageCards: true,
        canViewAuditLogs: true,
        canManageSafety: true,
        canEditRunbooks: true,
        requiresSecondApprover: true,
      ),
      WarRoomRole.safetyOfficer: const RolePermission(
        role: WarRoomRole.safetyOfficer,
        canPausePPV: true,
        canManageCards: true,
        canViewAuditLogs: true,
        canManageSafety: true,
      ),
      WarRoomRole.promoterManager: const RolePermission(
        role: WarRoomRole.promoterManager,
        canManageCards: true,
      ),
      WarRoomRole.readOnlyAuditor: const RolePermission(
        role: WarRoomRole.readOnlyAuditor,
        canViewAuditLogs: true,
      ),
    });
  }

  void _seedUsers() {
    final now = DateTime.now();
    _users.addAll([
      WarRoomUser(
        uid: 'founder_1',
        displayName: 'Heath (Founder)',
        role: WarRoomRole.founderAdmin,
        twoFactorEnabled: true,
        lastLogin: now,
      ),
      WarRoomUser(
        uid: 'ops_1',
        displayName: 'Ops Lead',
        role: WarRoomRole.opsLead,
        twoFactorEnabled: true,
        lastLogin: now,
      ),
      WarRoomUser(
        uid: 'safety_1',
        displayName: 'Safety Officer',
        role: WarRoomRole.safetyOfficer,
        twoFactorEnabled: true,
        lastLogin: now,
      ),
      WarRoomUser(
        uid: 'promo_1',
        displayName: 'Promoter Manager',
        role: WarRoomRole.promoterManager,
        lastLogin: now,
      ),
      WarRoomUser(
        uid: 'audit_1',
        displayName: 'Auditor',
        role: WarRoomRole.readOnlyAuditor,
        lastLogin: now,
      ),
    ]);
    _currentUser = _users.first;
  }
}
