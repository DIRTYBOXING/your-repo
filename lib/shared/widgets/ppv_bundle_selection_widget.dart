import 'package:flutter/material.dart';

class PPVBundleSelectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> bundles;
  final int selectedBundle;
  final Function(int) onSelect;
  final Function(int) onBuy;

  const PPVBundleSelectionWidget({
    required this.bundles,
    required this.selectedBundle,
    required this.onSelect,
    required this.onBuy,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Text('PPV Bundle Selection Widget');
  }
}
