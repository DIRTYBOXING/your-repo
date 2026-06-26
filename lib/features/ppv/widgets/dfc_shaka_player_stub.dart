import 'package:flutter/widgets.dart';

class DfcShakaPlayer extends StatelessWidget {
  const DfcShakaPlayer({
    super.key,
    required this.manifestUrl,
    required this.drmToken,
    this.widevineLicenseUrl,
    this.fairplayLicenseUrl,
    this.fairplayCertificateUrl,
    this.isLive = false,
  });

  final String manifestUrl;
  final String drmToken;
  final String? widevineLicenseUrl;
  final String? fairplayLicenseUrl;
  final String? fairplayCertificateUrl;
  final bool isLive;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
