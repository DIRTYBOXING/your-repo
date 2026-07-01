import 'package:flutter/material.dart';

class MessageSearchBar extends StatelessWidget {
  final ValueChanged<String> onSearch;

  const MessageSearchBar({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search messages...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: onSearch,
      ),
    );
  }
}
