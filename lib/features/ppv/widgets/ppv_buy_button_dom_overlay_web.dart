import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

Widget buildPpvBuyButtonDomOverlay({
  required VoidCallback onPressed,
  required String automationLabel,
}) {
  return Positioned.fill(
    child: Opacity(
      opacity: 0.02,
      child: HtmlElementView.fromTagName(
        tagName: 'button',
        onElementCreated: (element) {
          final button = element as web.HTMLButtonElement;
          button.id = 'ppv-detail-buy-button-dom';
          button.type = 'button';
          button.textContent = automationLabel;
          button.setAttribute('data-test', 'ppv-purchase-cta');
          button.setAttribute('aria-label', automationLabel);
          button.title = 'ppv-detail-buy-button-dom';
          button.style
            ..width = '100%'
            ..height = '100%'
            ..border = '0'
            ..padding = '0'
            ..margin = '0'
            ..background = 'transparent'
            ..cursor = 'pointer';
          button.onclick = ((web.MouseEvent _) {
            onPressed();
          }).toJS;
        },
      ),
    ),
  );
}
