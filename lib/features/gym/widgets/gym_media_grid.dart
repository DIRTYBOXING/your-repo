import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class GymMediaGrid extends StatelessWidget {
  final List<String> media;

  const GymMediaGrid({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: media.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (_, i) {
        return Container(
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(12),
            image: media[i].isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(media[i]),
                    fit: BoxFit.cover,
                  )
                : null,
            border: Border.all(color: Colors.white10),
          ),
          child: media[i].isEmpty
              ? const Center(child: Icon(Icons.image, color: Colors.white24))
              : null,
        );
      },
    );
  }
}
