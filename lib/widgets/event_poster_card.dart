import 'package:flutter/material.dart';

class EventPosterCard extends StatelessWidget {
  final String eventId;
  final String title;
  final String posterUrl;
  final String dateTimeLabel;
  final String priceLabel;
  final VoidCallback onBuy;
  final VoidCallback onTeaser;

  const EventPosterCard({
    super.key,
    required this.eventId,
    required this.title,
    required this.posterUrl,
    required this.dateTimeLabel,
    required this.priceLabel,
    required this.onBuy,
    required this.onTeaser,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title poster',
      child: Card(
        elevation: 2,
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                key: ValueKey('event-poster-$eventId'),
                color: Colors.grey.shade900,
                child: Image.network(
                  posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    dateTimeLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        key: ValueKey('buy-$eventId'),
                        onPressed: onBuy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.black,
                          elevation: 0,
                        ),
                        child: Text('Buy Livestream Ticket • $priceLabel'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        key: ValueKey('teaser-$eventId'),
                        onPressed: onTeaser,
                        child: const Text('Teaser'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
