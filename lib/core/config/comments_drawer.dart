import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class CommentsDrawer extends StatelessWidget {
  final List<Map<String, String>> comments;

  const CommentsDrawer({super.key, required this.comments});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: DesignTokens.bgPrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: ListView.builder(
            controller: controller,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: comments.length,
            itemBuilder: (_, i) {
              final c = comments[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c["author"]!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c["text"]!,
                      style: const TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
