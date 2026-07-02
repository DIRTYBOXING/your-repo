import 'package:flutter/material.dart';

class PpvTicketCard extends StatelessWidget {
  const PpvTicketCard({
    super.key,
    required this.title,
    required this.price,
    required this.onBuy,
  });

  final String title;
  final String price;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(price),
        trailing: ElevatedButton(onPressed: onBuy, child: const Text('Buy')),
      ),
    );
  }
}
