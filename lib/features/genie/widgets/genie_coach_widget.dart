import 'package:flutter/material.dart';
import '../genie_persona.dart';

/// GenieCoachWidget
/// Persistent Genie coach/mentor widget for dashboard, training, and wellness screens.

class GenieCoachWidget extends StatefulWidget {
  final String? message;
  final VoidCallback? onAskGenie;
  final bool isEncouragement;

  const GenieCoachWidget({
    super.key,
    this.message,
    this.onAskGenie,
    this.isEncouragement = false,
  });

  @override
  State<GenieCoachWidget> createState() => _GenieCoachWidgetState();
}

class _GenieCoachWidgetState extends State<GenieCoachWidget> {
  GeniePersona _selectedPersona = geniePersonas.first;

  Future<void> _showPersonaPicker() async {
    final picked = await showModalBottomSheet<GeniePersona>(
      context: context,
      builder: (context) => ListView(
        children: [
          for (final persona in geniePersonas)
            ListTile(
              leading: Icon(persona.icon, color: Colors.deepPurple),
              title: Text(persona.displayName),
              subtitle: Text(persona.description),
              trailing: _selectedPersona.id == persona.id
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () => Navigator.pop(context, persona),
            ),
        ],
      ),
    );
    if (picked != null && picked.id != _selectedPersona.id) {
      setState(() => _selectedPersona = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: widget.onAskGenie,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isEncouragement
                        ? [Colors.purpleAccent, Colors.blueAccent]
                        : [Colors.amber, Colors.orangeAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_selectedPersona.icon, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.message ??
                            (widget.isEncouragement
                                ? 'Keep going, champ! Shido believes in you.'
                                : 'Ask ${_selectedPersona.displayName} for advice or motivation!'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showPersonaPicker,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_search, color: Colors.deepPurple, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'Change Mentor',
                    style: TextStyle(color: Colors.deepPurple, fontSize: 13),
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
