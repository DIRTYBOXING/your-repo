import 'dart:async';
import 'package:flutter/material.dart';
import '../genie_persona.dart';
import '../genie_api_service.dart';
import '../../../shared/widgets/dfc_background.dart';

/// Genie Chat Screen
/// Full-screen chat interface with AI mentor personas including Samurai Shido
class GenieChatScreen extends StatefulWidget {
  final GeniePersona? initialPersona;

  const GenieChatScreen({super.key, this.initialPersona});

  @override
  State<GenieChatScreen> createState() => _GenieChatScreenState();
}

class _GenieChatScreenState extends State<GenieChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late GeniePersona _selectedPersona;
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Default to Samurai Shido if available, otherwise first persona
    _selectedPersona =
        widget.initialPersona ??
        geniePersonas.firstWhere(
          (p) => p.id == 'shido',
          orElse: () => geniePersonas.first,
        );

    // Welcome message
    _messages.add(
      ChatMessage(
        text:
            'Hey, I\'m ${_selectedPersona.displayName}. I\'ll keep it simple and useful.\n\nWhat do you need help with right now?',
        isUser: false,
        persona: _selectedPersona,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Hide typing indicator after 0.8 seconds for instant feel
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _isTyping) {
        setState(() => _isTyping = false);
      }
    });

    try {
      // Build conversation history from recent user messages for context
      final history = _messages
          .where((m) => m.isUser)
          .map((m) => m.text)
          .toList();

      final response =
          await GenieApiService.askGenie(
            text,
            persona: _selectedPersona,
            conversationHistory: history,
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Request took too long');
            },
          );

      setState(() {
        _messages.add(
          ChatMessage(text: response, isUser: false, persona: _selectedPersona),
        );
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: e.toString().contains('Timeout')
                ? 'Taking too long. Try again?'
                : 'I\'m having trouble connecting right now. Try again in a moment.',
            isUser: false,
            persona: _selectedPersona,
            isError: true,
          ),
        );
        _isTyping = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _changePersona() async {
    final picked = await showModalBottomSheet<GeniePersona>(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Choose Your Mentor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...geniePersonas
                .where((p) => p.id != 'posterboy')
                .map(
                  (persona) => ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedPersona.id == persona.id
                            ? Colors.amber.withValues(alpha: 0.2)
                            : Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        persona.icon,
                        color: _selectedPersona.id == persona.id
                            ? Colors.amber
                            : Colors.purple,
                      ),
                    ),
                    title: Text(
                      persona.displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: _selectedPersona.id == persona.id
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      persona.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    trailing: _selectedPersona.id == persona.id
                        ? const Icon(Icons.check_circle, color: Colors.amber)
                        : null,
                    onTap: () => Navigator.pop(context, persona),
                  ),
                ),
          ],
        ),
      ),
    );

    if (picked != null && picked.id != _selectedPersona.id) {
      setState(() {
        _selectedPersona = picked;
        _messages.add(
          ChatMessage(
            text:
                'I am ${_selectedPersona.displayName}. ${_selectedPersona.quote}\n\nLet\'s continue our conversation.',
            isUser: false,
            persona: _selectedPersona,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.purple.shade900,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_selectedPersona.icon, color: Colors.amber),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedPersona.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'AI Mentor',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Change Mentor',
            onPressed: _changePersona,
          ),
        ],
      ),
      body: DFCBackground(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),

            // Typing indicator
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _selectedPersona.icon,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Thinking...',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

            // Input bar
            SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade900.withValues(alpha: 0.85),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      offset: Offset(0, -2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Ask Samurai Shido anything...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.amber,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.black),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: message.isError
                    ? Colors.red.withValues(alpha: 0.2)
                    : Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                message.persona?.icon ?? Icons.smart_toy,
                color: message.isError ? Colors.red : Colors.amber,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Colors.purple.shade700
                    : message.isError
                    ? Colors.red.shade900.withValues(alpha: 0.3)
                    : Colors.grey.shade900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isUser && message.persona != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.persona!.displayName,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, color: Colors.blue, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final GeniePersona? persona;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.persona,
    this.isError = false,
  });
}
