import 'package:flutter/material.dart';

class ConversationModel {
  final String id;
  final String name;
  final String role;
  final String lastMessage;
  final String timeAgo;
  final int unreadCount;
  final Color color;
  final String avatarUrl;

  ConversationModel({
    required this.id,
    required this.name,
    required this.role,
    required this.lastMessage,
    required this.timeAgo,
    required this.unreadCount,
    required this.color,
    required this.avatarUrl,
  });
}