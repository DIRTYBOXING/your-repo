import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class DfcShakaPlayer extends StatefulWidget {
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
  State<DfcShakaPlayer> createState() => _DfcShakaPlayerState();
}

class _DfcShakaPlayerState extends State<DfcShakaPlayer> {
  web.HTMLDivElement? _container;

  JSObject? get _bridge {
    final value = globalContext.getProperty<JSAny?>('dfcShakaPlayer'.toJS);
    if (value == null) {
      return null;
    }
    return value as JSObject;
  }

  JSObject _configToJs() {
    return ({
          'manifestUrl': widget.manifestUrl,
          'drmToken': widget.drmToken,
          if (widget.widevineLicenseUrl?.isNotEmpty ?? false)
            'widevineLicenseUrl': widget.widevineLicenseUrl,
          if (widget.fairplayLicenseUrl?.isNotEmpty ?? false)
            'fairplayLicenseUrl': widget.fairplayLicenseUrl,
          if (widget.fairplayCertificateUrl?.isNotEmpty ?? false)
            'fairplayCertificateUrl': widget.fairplayCertificateUrl,
          'autoplay': true,
          'isLive': widget.isLive,
          'startMuted': false,
        }.jsify()!
        as JSObject);
  }

  void _mountPlayer(web.HTMLDivElement element) {
    _container = element;
    element.style
      ..width = '100%'
      ..height = '100%'
      ..background = '#000'
      ..display = 'block';

    final bridge = _bridge;
    if (bridge == null) {
      element.textContent = 'DRM web player bridge unavailable';
      return;
    }

    bridge.callMethod<JSAny?>('mount'.toJS, element, _configToJs());
  }

  void _updatePlayer() {
    final container = _container;
    final bridge = _bridge;
    if (container == null || bridge == null) {
      return;
    }

    bridge.callMethod<JSAny?>('update'.toJS, container, _configToJs());
  }

  @override
  void didUpdateWidget(covariant DfcShakaPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.manifestUrl != widget.manifestUrl ||
        oldWidget.drmToken != widget.drmToken ||
        oldWidget.widevineLicenseUrl != widget.widevineLicenseUrl ||
        oldWidget.fairplayLicenseUrl != widget.fairplayLicenseUrl ||
        oldWidget.fairplayCertificateUrl != widget.fairplayCertificateUrl) {
      _updatePlayer();
    }
  }

  @override
  void dispose() {
    final container = _container;
    final bridge = _bridge;
    if (container != null && bridge != null) {
      bridge.callMethod<JSAny?>('destroy'.toJS, container);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView.fromTagName(
      tagName: 'div',
      onElementCreated: (element) {
        _mountPlayer(element as web.HTMLDivElement);
      },
    );
  }
}
