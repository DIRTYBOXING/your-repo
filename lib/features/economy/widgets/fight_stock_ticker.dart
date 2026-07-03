import 'package:flutter/material.dart';
import '../../../shared/widgets/glass_card.dart';

class FightStockTicker extends StatelessWidget {
  const FightStockTicker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStockItem('J. JONES', '+5.2%', true),
          _buildStockItem('I. MAKHACHEV', '+1.1%', true),
          _buildStockItem('C. MCGREGOR', '-2.4%', false),
          _buildStockItem('A. VOLKANOVSKI', '+3.8%', true),
          _buildStockItem('S. STRICKLAND', '-0.5%', false),
        ],
      ),
    );
  }

  Widget _buildStockItem(String fighter, String change, bool isUp) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fighter,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Icon(
                isUp ? Icons.trending_up : Icons.trending_down,
                color: isUp ? Colors.greenAccent : Colors.redAccent,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(
                  color: isUp ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
