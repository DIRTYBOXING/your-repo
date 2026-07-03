import 'package:flutter/material.dart';
import '../../../fighter_controller.dart';
import '../../../fighter_repository.dart';
import '../../../api_service.dart';
import '../../../fighter_state.dart';
import '../../../fighter_model.dart';

class FightersScreen extends StatefulWidget {
  const FightersScreen({super.key});

  @override
  State<FightersScreen> createState() => _FightersScreenState();
}

class _FightersScreenState extends State<FightersScreen> {
  late final FighterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FighterController(
      repository: FighterRepository(apiService: ApiService()),
    );
    _controller.fetchFighters();
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
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final state = _controller.state;

            if (state is FighterInitial || state is FighterLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
            }

            if (state is FighterError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${state.message}',
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (state is FighterLoaded) {
              return _buildContent(state.fighters);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(List<FighterModel> fighters) {
    return RefreshIndicator(
      onRefresh: _controller.fetchFighters,
      color: Colors.blueAccent,
      backgroundColor: const Color(0xFF0A0E17),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _header(),
          const SizedBox(height: 32),
          if (fighters.isEmpty)
            const Center(
              child: Text(
                'No fighters found.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          else
            ...fighters.map((f) => _fighterCard(f)),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'FIGHTER ROSTER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
          ),
          child: const Text(
            'ACTIVE',
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fighterCard(FighterModel fighter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white10,
            backgroundImage: NetworkImage(
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(fighter.name)}&background=0D8ABC&color=fff',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fighter.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fighter.weightClass,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${fighter.wins}-${fighter.losses}-0',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'RECORD',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
