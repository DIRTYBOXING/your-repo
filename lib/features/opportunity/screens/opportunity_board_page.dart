import 'package:flutter/material.dart';

/// DFC Opportunity Board — Events, Gyms, Tryouts, Sponsorships
/// Central hub for discovering and posting opportunities in combat sports.
class OpportunityBoardPage extends StatelessWidget {
  final List<Opportunity> opportunities;
  const OpportunityBoardPage({required this.opportunities, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.teal.shade900,
        title: const Text(
          'Opportunity Board',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            tooltip: 'Post Opportunity',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email opportunities@datafightcentral.com to post a listing'),
                  backgroundColor: Colors.teal,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ...opportunities.map((o) => _buildOpportunityCard(context, o)),
        ],
      ),
    );
  }

  Widget _buildOpportunityCard(BuildContext context, Opportunity o) {
    return Card(
      color: Colors.teal.shade800.withValues(alpha: 0.90),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 7,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconForType(o.type), color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  o.title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    o.type,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.teal.shade700,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              o.description,
              style: const TextStyle(fontSize: 15, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white54, size: 18),
                const SizedBox(width: 4),
                Text(o.location, style: const TextStyle(color: Colors.white54)),
                const SizedBox(width: 16),
                const Icon(Icons.calendar_today, color: Colors.white54, size: 18),
                const SizedBox(width: 4),
                Text(o.date, style: const TextStyle(color: Colors.white54)),
              ],
            ),
            if (o.link != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening opportunity link...'),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  },
                  child: Text(
                    'More info',
                    style: TextStyle(
                      color: Colors.tealAccent.shade100,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            if (o.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  children: o.tags
                      .map(
                        (t) => Chip(
                          label: Text(t),
                          backgroundColor: Colors.teal.shade900,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'event':
        return Icons.sports_mma;
      case 'tryout':
        return Icons.how_to_reg;
      case 'gym':
        return Icons.fitness_center;
      case 'sponsorship':
        return Icons.attach_money;
      default:
        return Icons.star;
    }
  }
}

class Opportunity {
  final String title;
  final String type; // event, tryout, gym, sponsorship, etc.
  final String description;
  final String location;
  final String date;
  final String? link;
  final List<String> tags;

  const Opportunity({
    required this.title,
    required this.type,
    required this.description,
    required this.location,
    required this.date,
    this.link,
    this.tags = const [],
  });
}

/// Usage Example:
/// OpportunityBoardPage(opportunities: [
///   Opportunity(
///     title: 'Muay Thai Nationals',
///     type: 'Event',
///     description: 'National championship for all ages and genders. Register now!',
///     location: 'Sydney, Australia',
///     date: '2026-04-12',
///     link: 'https://muaythainationals.com',
///     tags: ['Muay Thai', 'Youth', 'Women'],
///   ),
///   // ...more opportunities
/// ])
