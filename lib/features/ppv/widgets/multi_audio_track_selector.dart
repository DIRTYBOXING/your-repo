import 'package:flutter/material.dart';

///═══════════════════════════════════════════════════════════════════════════
/// MULTI-AUDIO TRACK SELECTOR — Choose Your Commentary
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Let viewers pick their audio experience during live streams:
///   • Pro Analyst (technical breakdowns)
///   • Casual Fan (hype & entertainment)
///   • Fighter's Coach (corner perspective)
///   • Ambient Only (crowd + action sounds)
///   • Language options (EN, ES, PT, etc.)
///
/// Integrates with HLS stream alternate audio tracks or separate streams.
/// Stores user preference for future events.
///
/// Example HLS Manifest:
///   #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="Pro",DEFAULT=YES,URI="pro.m3u8"
///   #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="Casual",URI="casual.m3u8"
///   #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="Coach",URI="coach.m3u8"
/// ═══════════════════════════════════════════════════════════════════════════

enum AudioTrack { pro, casual, coach, ambient, spanish, portuguese, french }

class AudioTrackOption {
  final AudioTrack track;
  final String name;
  final String description;
  final IconData icon;
  final bool available;

  const AudioTrackOption({
    required this.track,
    required this.name,
    required this.description,
    required this.icon,
    this.available = true,
  });
}

class MultiAudioTrackSelector extends StatelessWidget {
  final AudioTrack selectedTrack;
  final ValueChanged<AudioTrack> onTrackChanged;
  final List<AudioTrack>? availableTracks;

  const MultiAudioTrackSelector({
    super.key,
    required this.selectedTrack,
    required this.onTrackChanged,
    this.availableTracks,
  });

  static const Map<AudioTrack, AudioTrackOption> _trackOptions = {
    AudioTrack.pro: AudioTrackOption(
      track: AudioTrack.pro,
      name: 'Pro Analyst',
      description: 'Technical breakdowns & stats',
      icon: Icons.analytics,
    ),
    AudioTrack.casual: AudioTrackOption(
      track: AudioTrack.casual,
      name: 'Casual Fan',
      description: 'Hype mode & entertainment',
      icon: Icons.celebration,
    ),
    AudioTrack.coach: AudioTrackOption(
      track: AudioTrack.coach,
      name: 'Fighter\'s Coach',
      description: 'Corner perspective',
      icon: Icons.sports_martial_arts,
    ),
    AudioTrack.ambient: AudioTrackOption(
      track: AudioTrack.ambient,
      name: 'Ambient Only',
      description: 'Crowd & action sounds',
      icon: Icons.volume_up,
    ),
    AudioTrack.spanish: AudioTrackOption(
      track: AudioTrack.spanish,
      name: 'Español',
      description: 'Spanish commentary',
      icon: Icons.language,
    ),
    AudioTrack.portuguese: AudioTrackOption(
      track: AudioTrack.portuguese,
      name: 'Português',
      description: 'Portuguese commentary',
      icon: Icons.language,
    ),
    AudioTrack.french: AudioTrackOption(
      track: AudioTrack.french,
      name: 'Français',
      description: 'French commentary',
      icon: Icons.language,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.95),
            Colors.grey.shade900.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Row(
            children: [
              const Icon(Icons.headset, color: Colors.cyanAccent, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Choose Your Commentary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Track options
          ..._getAvailableOptions().map((option) {
            final isSelected = option.track == selectedTrack;
            final isAvailable = option.available;

            return GestureDetector(
              onTap: isAvailable
                  ? () {
                      onTrackChanged(option.track);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🎧 Switched to ${option.name}'),
                          backgroundColor: Colors.cyanAccent,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.cyanAccent.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.cyanAccent
                        : Colors.white.withValues(alpha: 0.1),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.cyanAccent.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        option.icon,
                        color: isSelected
                            ? Colors.cyanAccent
                            : isAvailable
                            ? Colors.white70
                            : Colors.white38,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                option.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.cyanAccent
                                      : isAvailable
                                      ? Colors.white
                                      : Colors.white38,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!isAvailable) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.orange.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'Coming Soon',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option.description,
                            style: TextStyle(
                              color: isAvailable
                                  ? Colors.white54
                                  : Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Selection indicator
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.cyanAccent,
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          // Info footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your preference is saved for future events',
                    style: TextStyle(color: Colors.blue, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<AudioTrackOption> _getAvailableOptions() {
    if (availableTracks == null) {
      return _trackOptions.values.toList();
    }

    return _trackOptions.entries
        .map(
          (entry) => AudioTrackOption(
            track: entry.value.track,
            name: entry.value.name,
            description: entry.value.description,
            icon: entry.value.icon,
            available: availableTracks!.contains(entry.key),
          ),
        )
        .toList();
  }
}

/// Quick floating button for audio track selection
class AudioTrackFloatingButton extends StatelessWidget {
  final AudioTrack currentTrack;
  final VoidCallback onTap;

  const AudioTrackFloatingButton({
    super.key,
    required this.currentTrack,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final option = MultiAudioTrackSelector._trackOptions[currentTrack]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.cyanAccent.withValues(alpha: 0.3),
              Colors.blue.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.cyanAccent.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(option.icon, color: Colors.cyanAccent, size: 16),
            const SizedBox(width: 6),
            Text(
              option.name,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
