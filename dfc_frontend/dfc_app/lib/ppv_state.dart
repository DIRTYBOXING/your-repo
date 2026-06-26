import '../models/ppv_model.dart';

/// V12 STATE MACHINE: PPV ENTITLEMENT
sealed class PpvState {}

class PpvInitial extends PpvState {}

class PpvLoading extends PpvState {}

class PpvAuthorized extends PpvState {
  final PpvEntitlementModel entitlement;
  PpvAuthorized(this.entitlement);
}

class PpvDenied extends PpvState {
  PpvDenied();
}

class PpvError extends PpvState {
  final String message;
  PpvError(this.message);
}
