import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' as vg;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'map_marker_service.dart';

class DfcMapMarkerIconService {
  DfcMapMarkerIconService._();

  static final DfcMapMarkerIconService instance = DfcMapMarkerIconService._();

  final Map<String, BitmapDescriptor> _cache = {};
  final Map<String, Future<BitmapDescriptor>> _pending = {};

  Future<BitmapDescriptor> iconForMarker(
    MapMarkerData marker, {
    bool highlighted = false,
  }) {
    final spec = _specFor(marker);
    final cacheKey =
        '${marker.type.name}:${spec.variantKey}:${highlighted ? 'selected' : 'idle'}';
    final cached = _cache[cacheKey];
    if (cached != null) {
      return Future.value(cached);
    }

    final inFlight = _pending[cacheKey];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _buildDescriptor(spec, highlighted: highlighted).then((
      icon,
    ) {
      _cache[cacheKey] = icon;
      _pending.remove(cacheKey);
      return icon;
    });

    _pending[cacheKey] = future;
    return future;
  }

  _MarkerVisualSpec _specFor(MapMarkerData marker) {
    switch (marker.type) {
      case MarkerType.gym:
        switch (marker.gymTier) {
          case GymTier.elite:
            return const _MarkerVisualSpec(
              variantKey: 'gym_elite',
              primary: Color(0xFFFFD54F),
              secondary: Color(0xFF4A3810),
              icon: Icons.fitness_center,
            );
          case GymTier.premier:
            return const _MarkerVisualSpec(
              variantKey: 'gym_premier',
              primary: Color(0xFF00E5FF),
              secondary: Color(0xFF0E2E40),
              icon: Icons.fitness_center,
            );
          case GymTier.community:
          case GymTier.standard:
          case null:
            return const _MarkerVisualSpec(
              variantKey: 'gym_standard',
              primary: Color(0xFF00E676),
              secondary: Color(0xFF123B25),
              icon: Icons.fitness_center,
            );
        }
      case MarkerType.event:
        if (marker.isLive) {
          return const _MarkerVisualSpec(
            variantKey: 'event_live',
            primary: Color(0xFFFF5252),
            secondary: Color(0xFF4D151C),
            icon: Icons.local_fire_department,
          );
        }
        if (marker.isPPV) {
          return const _MarkerVisualSpec(
            variantKey: 'event_ppv',
            primary: Color(0xFFFF4FD8),
            secondary: Color(0xFF4A163F),
            icon: Icons.ondemand_video,
          );
        }
        return const _MarkerVisualSpec(
          variantKey: 'event_upcoming',
          primary: Color(0xFF40C4FF),
          secondary: Color(0xFF123549),
          icon: Icons.event,
        );
      case MarkerType.campaign:
        switch (marker.campaignKind) {
          case CampaignKind.pinkShield:
            return const _MarkerVisualSpec(
              variantKey: 'campaign_pink_shield',
              primary: Color(0xFFFF5EA8),
              secondary: Color(0xFF4B1A34),
              icon: Icons.shield,
              assetPath: 'assets/campaigns/dfc_womens_health_shield.svg',
            );
          case CampaignKind.goldCoin:
            return const _MarkerVisualSpec(
              variantKey: 'campaign_gold_coin',
              primary: Color(0xFFFFC107),
              secondary: Color(0xFF4A3707),
              icon: Icons.monetization_on,
              assetPath: 'assets/campaigns/dfc_gold_coin_charity.svg',
            );
          case CampaignKind.coffeeNotCoffin:
            return const _MarkerVisualSpec(
              variantKey: 'campaign_coffee_not_coffin',
              primary: Color(0xFFFF8A65),
              secondary: Color(0xFF4A291C),
              icon: Icons.local_cafe,
              assetPath: 'assets/campaigns/dfc_coffee_not_coffin.svg',
            );
          case null:
            return const _MarkerVisualSpec(
              variantKey: 'campaign_default',
              primary: Color(0xFFB388FF),
              secondary: Color(0xFF30204A),
              icon: Icons.volunteer_activism,
            );
        }
      case MarkerType.mentor:
        return _MarkerVisualSpec(
          variantKey: marker.mentorTier == MentorTier.pinkDiamond
              ? 'mentor_pink_diamond'
              : 'mentor_gold_diamond',
          primary: marker.mentorTier == MentorTier.pinkDiamond
              ? const Color(0xFFFF6EC7)
              : const Color(0xFFFFD166),
          secondary: marker.mentorTier == MentorTier.pinkDiamond
              ? const Color(0xFF49203A)
              : const Color(0xFF4A3815),
          icon: marker.mentorTier == MentorTier.pinkDiamond
              ? Icons.diamond
              : Icons.workspace_premium,
        );
    }
  }

  Future<BitmapDescriptor> _buildDescriptor(
    _MarkerVisualSpec spec, {
    required bool highlighted,
  }) async {
    const width = 116.0;
    const height = 138.0;
    const center = Offset(width / 2, 46);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final glowPaint = Paint()
      ..color = spec.primary.withValues(alpha: highlighted ? 0.34 : 0.22)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 16);
    canvas.drawCircle(center, highlighted ? 33 : 29, glowPaint);

    final pinPath = Path()
      ..moveTo(center.dx - 16, 72)
      ..quadraticBezierTo(center.dx - 10, 95, center.dx, 116)
      ..quadraticBezierTo(center.dx + 10, 95, center.dx + 16, 72)
      ..close();

    canvas.drawPath(
      pinPath,
      Paint()..color = spec.primary.withValues(alpha: 0.72),
    );

    canvas.drawCircle(
      center,
      29,
      Paint()..color = spec.secondary.withValues(alpha: 0.96),
    );

    canvas.drawCircle(
      center,
      highlighted ? 26 : 24,
      Paint()
        ..color = spec.primary.withValues(alpha: highlighted ? 0.94 : 0.88),
    );

    canvas.drawCircle(
      center,
      highlighted ? 20 : 18,
      Paint()..color = const Color(0xFF04111E).withValues(alpha: 0.9),
    );

    canvas.drawCircle(
      center,
      highlighted ? 24 : 22,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlighted ? 3 : 2
        ..color = Colors.white.withValues(alpha: highlighted ? 0.9 : 0.7),
    );

    await _paintMarkerCore(canvas, center, spec, highlighted: highlighted);

    canvas.drawCircle(
      const Offset(width / 2, 118),
      4,
      Paint()..color = spec.primary,
    );

    final image = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(Uint8List.view(byteData!.buffer));
  }
}

extension on DfcMapMarkerIconService {
  Future<void> _paintMarkerCore(
    Canvas canvas,
    Offset center,
    _MarkerVisualSpec spec, {
    required bool highlighted,
  }) async {
    if (spec.assetPath != null) {
      final pictureInfo = await vg.vg.loadPicture(
        vg.SvgAssetLoader(spec.assetPath!),
        null,
      );
      final dimension = highlighted ? 30 : 28;
      final image = await pictureInfo.picture.toImage(dimension, dimension);
      final destination = Rect.fromCenter(
        center: center,
        width: dimension.toDouble(),
        height: dimension.toDouble(),
      );
      canvas.save();
      canvas.clipPath(
        Path()..addOval(
          Rect.fromCircle(center: center, radius: highlighted ? 16 : 15),
        ),
      );
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        destination,
        Paint(),
      );
      canvas.restore();
      pictureInfo.picture.dispose();
      return;
    }

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(spec.icon.codePoint),
        style: TextStyle(
          fontSize: highlighted ? 24 : 22,
          fontFamily: spec.icon.fontFamily,
          package: spec.icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    iconPainter.paint(
      canvas,
      Offset(
        center.dx - iconPainter.width / 2,
        center.dy - iconPainter.height / 2,
      ),
    );
  }
}

class _MarkerVisualSpec {
  const _MarkerVisualSpec({
    required this.variantKey,
    required this.primary,
    required this.secondary,
    required this.icon,
    this.assetPath,
  });

  final String variantKey;
  final Color primary;
  final Color secondary;
  final IconData icon;
  final String? assetPath;
}
