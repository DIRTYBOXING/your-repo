import 'package:flutter/material.dart';

class PPVBundleSelectionWidget extends StatefulWidget {
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
  State<PPVBundleSelectionWidget> createState() =>
      _PPVBundleSelectionWidgetState();
}

class _PPVBundleSelectionWidgetState extends State<PPVBundleSelectionWidget> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.bundles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final bundle = widget.bundles[i];
          final selected = widget.selectedBundle == i;
          return GestureDetector(
            onTap: () => widget.onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected
                    ? bundle['color'].withAlpha(46)
                    : Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? bundle['color'].withAlpha(128)
                      : Colors.white.withAlpha(25),
                  width: 1.2,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: bundle['color'].withAlpha(46),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified, color: bundle['color'], size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bundle['name'],
                          style: TextStyle(
                            color: bundle['color'],
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bundle['desc'],
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${bundle['price'].toStringAsFixed(2)}',
                    style: TextStyle(
                      color: bundle['color'],
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bundle['color'],
                      foregroundColor: Colors.black,
                      minimumSize: const Size(120, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => widget.onBuy(i),
                    child: Text(selected ? 'SELECTED' : 'BUY NOW'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
