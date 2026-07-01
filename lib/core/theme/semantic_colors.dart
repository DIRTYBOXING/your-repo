import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC SEMANTIC COLOR EXTENSION
/// ThemeExtension for success / warning / danger / info beyond Material's
/// built-in colorScheme.error. Access via Theme.of(context).extension(DFCSemanticColors)
/// ═══════════════════════════════════════════════════════════════════════════
@immutable
class DFCSemanticColors extends ThemeExtension<DFCSemanticColors> {
  final Color success;
  final Color onSuccess;
  final Color successContainer;

  final Color warning;
  final Color onWarning;
  final Color warningContainer;

  final Color danger;
  final Color onDanger;
  final Color dangerContainer;

  final Color info;
  final Color onInfo;
  final Color infoContainer;

  const DFCSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.danger,
    required this.onDanger,
    required this.dangerContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
  });

  /// Default neon theme values
  static const DFCSemanticColors neonDark = DFCSemanticColors(
    success: Color(0xFF39FF14),
    onSuccess: Color(0xFF0A0E1A),
    successContainer: Color(0x2039FF14),
    warning: Color(0xFFFFBE21),
    onWarning: Color(0xFF0A0E1A),
    warningContainer: Color(0x20FFBE21),
    danger: Color(0xFFFF4757),
    onDanger: Color(0xFFFFFFFF),
    dangerContainer: Color(0x20FF4757),
    info: Color(0xFF00FFF0),
    onInfo: Color(0xFF0A0E1A),
    infoContainer: Color(0x2000FFF0),
  );

  @override
  DFCSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? danger,
    Color? onDanger,
    Color? dangerContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
  }) {
    return DFCSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
    );
  }

  @override
  DFCSemanticColors lerp(DFCSemanticColors? other, double t) {
    if (other is! DFCSemanticColors) return this;
    return DFCSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
    );
  }
}

/// Convenience extension on BuildContext
extension DFCSemanticColorsExt on BuildContext {
  DFCSemanticColors get semanticColors =>
      Theme.of(this).extension<DFCSemanticColors>() ??
      DFCSemanticColors.neonDark;
}
