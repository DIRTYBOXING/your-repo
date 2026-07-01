import 'package:flutter/material.dart';
import 'api_service.dart';
import 'blue/controllers/pickem_controller.dart';
import 'blue/models/pickem_model.dart';
import 'blue/repositories/pickem_repository.dart';
import 'blue/state/pickem_state.dart';

class FanPickemsScreen extends StatefulWidget {
  const FanPickemsScreen({super.key});

  @override
  State<FanPickemsScreen> createState() => _FanPickemsScreenState();
}

class _FanPickemsScreenState extends State<FanPickemsScreen> {
  late final PickemController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PickemController(repo: PickemRepository(api: ApiService()))
      ..loadPickems();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _makePick(String pickemId, String selection) {
    _controller.submitPick(pickemId, selection);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Locked in: $selection'),
        backgroundColor: Colors.cyanAccent,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            // ─── HEADER ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'FAN PICK\'EMS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── CONTENT ─────────────────────────────────────────────────────
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final state = _controller.state;

                  if (state is PickemInitial || state is PickemLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.cyanAccent,
                      ),
                    );
                  }
                  if (state is PickemError) {
                    return Center(
                      child: Text(
                        'Error: ${state.message}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }
                  if (state is PickemLoaded) {
                    return RefreshIndicator(
                      onRefresh: _controller.loadPickems,
                      color: Colors.cyanAccent,
                      backgroundColor: const Color(0xFF0A0E17),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        itemCount: state.pickems.length,
                        itemBuilder: (context, index) {
                          return _buildPickemCard(state.pickems[index]);
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickemCard(PickemModel pickem) {
    final isOpen = pickem.status == 'OPEN';
    final hasPicked = pickem.userPick != null;

    Color statusColor = Colors.cyanAccent;
    String statusText = 'OPEN';

    if (pickem.status == 'WON') {
      statusColor = Colors.greenAccent;
      statusText = 'WON +${pickem.rewardTokens}';
    } else if (pickem.status == 'LOST') {
      statusColor = Colors.redAccent;
      statusText = 'LOST';
    } else if (hasPicked) {
      statusColor = Colors.amberAccent;
      statusText = 'PICK LOCKED';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: hasPicked && isOpen
            ? [
                BoxShadow(
                  color: Colors.amberAccent.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pickem.eventName,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  pickem.redCorner.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    decoration:
                        (pickem.status == 'LOST' &&
                            pickem.userPick == pickem.redCorner)
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  pickem.blueCorner.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    decoration:
                        (pickem.status == 'LOST' &&
                            pickem.userPick == pickem.blueCorner)
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (isOpen)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pickem.userPick == pickem.redCorner
                          ? Colors.redAccent
                          : Colors.redAccent.withValues(alpha: 0.1),
                      foregroundColor: pickem.userPick == pickem.redCorner
                          ? Colors.white
                          : Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    onPressed: () => _makePick(pickem.id, pickem.redCorner),
                    child: const Text('PICK RED'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pickem.userPick == pickem.blueCorner
                          ? Colors.blueAccent
                          : Colors.blueAccent.withValues(alpha: 0.1),
                      foregroundColor: pickem.userPick == pickem.blueCorner
                          ? Colors.white
                          : Colors.blueAccent,
                      side: const BorderSide(color: Colors.blueAccent),
                    ),
                    onPressed: () => _makePick(pickem.id, pickem.blueCorner),
                    child: const Text('PICK BLUE'),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),
          Text(
            'WINNER GETS ${pickem.rewardTokens} DFC TOKENS',
            style: const TextStyle(
              color: Colors.amberAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
