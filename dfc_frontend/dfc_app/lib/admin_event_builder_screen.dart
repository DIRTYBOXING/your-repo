import 'package:flutter/material.dart';
import 'event_controller.dart';
import 'event_repository.dart';
import 'event_model.dart';
import 'event_state.dart';
import 'api_service.dart';

// ─── MAIN SCREEN ─────────────────────────────────────────────────────────────
class AdminEventBuilderScreen extends StatefulWidget {
  const AdminEventBuilderScreen({super.key});

  @override
  State<AdminEventBuilderScreen> createState() =>
      _AdminEventBuilderScreenState();
}

class _AdminEventBuilderScreenState extends State<AdminEventBuilderScreen> {
  late final EventController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EventController(
      repository: EventRepository(apiService: ApiService()),
    );
    _controller.loadEvents();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        elevation: 0,
        title: const Text(
          'ADMIN: EVENT BUILDER',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent.withValues(alpha: 0.1),
                foregroundColor: Colors.cyanAccent,
                side: const BorderSide(color: Colors.cyanAccent),
              ),
              icon: const Icon(Icons.add),
              label: const Text("NEW EVENT"),
              onPressed: () => _showEventDialog(context),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final state = _controller.state;

          if (state is EventInitial || state is EventLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            );
          }

          if (state is EventError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (state is EventLoaded) {
            return RefreshIndicator(
              onRefresh: _controller.loadEvents,
              color: Colors.cyanAccent,
              backgroundColor: const Color(0xFF0A0E17),
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: state.events.length,
                itemBuilder: (context, index) {
                  return _buildEventCard(state.events[index]);
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${event.date}  •  ${event.location}",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white54),
                      onPressed: () =>
                          _showEventDialog(context, existingEvent: event),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _showFightCardBuilder(context, event),
                      child: const Text("BUILD CARD"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Fights Preview
          Padding(
            padding: const EdgeInsets.all(16),
            child: event.fights.isEmpty
                ? const Text(
                    "No fights added to this card yet.",
                    style: TextStyle(
                      color: Colors.white38,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Column(
                    children: event.fights.map((fight) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            if (fight.isMainEvent)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.2,
                                  ),
                                  border: Border.all(color: Colors.redAccent),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "MAIN",
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Text(
                              "${fight.redCorner} vs ${fight.blueCorner}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              fight.weightClass,
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── DIALOGS ────────────────────────────────────────────────────────────────

  void _showEventDialog(BuildContext context, {EventModel? existingEvent}) {
    final nameCtrl = TextEditingController(text: existingEvent?.name ?? '');
    final dateCtrl = TextEditingController(text: existingEvent?.date ?? '');
    final locCtrl = TextEditingController(text: existingEvent?.location ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0E17),
        title: Text(
          existingEvent == null ? 'CREATE NEW EVENT' : 'EDIT EVENT',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DarkTextField(
              controller: nameCtrl,
              label: "Event Name (e.g. DFC 2)",
            ),
            const SizedBox(height: 12),
            _DarkTextField(controller: dateCtrl, label: "Date (YYYY-MM-DD)"),
            const SizedBox(height: 12),
            _DarkTextField(controller: locCtrl, label: "Location"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "CANCEL",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            onPressed: () {
              if (existingEvent == null) {
                _controller.createEvent(
                  nameCtrl.text,
                  dateCtrl.text,
                  locCtrl.text,
                );
              } else {
                _controller.updateEvent(existingEvent.id, {
                  'name': nameCtrl.text,
                  'date': dateCtrl.text,
                  'location': locCtrl.text,
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text(
              "SAVE",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFightCardBuilder(BuildContext context, EventModel event) {
    final redCtrl = TextEditingController();
    final blueCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    bool isMain = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0A0E17),
            title: Text(
              'ADD FIGHT TO ${event.name}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DarkTextField(
                        controller: redCtrl,
                        label: "Red Corner",
                        borderColor: Colors.redAccent,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "VS",
                        style: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _DarkTextField(
                        controller: blueCtrl,
                        label: "Blue Corner",
                        borderColor: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DarkTextField(
                  controller: weightCtrl,
                  label: "Weight Class (e.g. Lightweight)",
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text(
                    "Set as Main Event",
                    style: TextStyle(color: Colors.white),
                  ),
                  value: isMain,
                  activeColor: Colors.redAccent,
                  checkColor: Colors.white,
                  onChanged: (val) {
                    setDialogState(() => isMain = val ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "DONE",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () {
                  if (redCtrl.text.isNotEmpty && blueCtrl.text.isNotEmpty) {
                    _controller.addFightToEvent(
                      event.id,
                      event.fights,
                      FightModel(
                        redCorner: redCtrl.text,
                        blueCorner: blueCtrl.text,
                        weightClass: weightCtrl.text.isEmpty
                            ? 'Catchweight'
                            : weightCtrl.text,
                        isMainEvent: isMain,
                      ),
                    );
                    // Clear for next entry
                    redCtrl.clear();
                    blueCtrl.clear();
                    weightCtrl.clear();
                    setDialogState(() => isMain = false);
                  }
                },
                child: const Text(
                  "ADD TO CARD",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── REUSABLE WIDGETS ────────────────────────────────────────────────────────

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color borderColor;

  const _DarkTextField({
    required this.controller,
    required this.label,
    this.borderColor = Colors.white24,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.cyanAccent),
        ),
        filled: true,
        fillColor: Colors.black26,
      ),
    );
  }
}
