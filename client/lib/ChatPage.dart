import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  final String? initialRoomId;
  final String? initialRoomName;

  const ChatPage({super.key, this.initialRoomId, this.initialRoomName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  String? _currentRoomId;
  String? _currentRoomName;
  List<Map<String, String>> _rooms = []; // {id, name}

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      return;
    }
    final now = TimeOfDay.now();
    final timeStr = now.format(context);

    setState(() {
      _messages.add({
        'text': message,
        'isUser': true,
        'time': timeStr,
      });
      _messageController.clear();
    });
    _saveMessages();
  }

  Future<void> _saveMessages() async {
    if (_currentRoomId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_room_$_currentRoomId', jsonEncode(_messages));
  }

  Future<void> _loadRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('chat_rooms');
    if (raw != null && raw.isNotEmpty) {
      try {
        final parsed = jsonDecode(raw) as List<dynamic>;
        _rooms = parsed
            .whereType<Map<String, dynamic>>()
            .map((m) => {
                  'id': (m['id'] ?? '').toString(),
                  'name': (m['name'] ?? '').toString()
                })
            .toList();
      } catch (_) {
        _rooms = [];
      }
    }
  }

  Future<void> _loadMessagesForCurrentRoom() async {
    if (_currentRoomId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('chat_room_$_currentRoomId');
    if (raw != null && raw.isNotEmpty) {
      try {
        final parsed = jsonDecode(raw) as List<dynamic>;
        setState(() {
          _messages.clear();
          _messages.addAll(parsed
              .whereType<Map<String, dynamic>>()
              .map((m) => {
                    'text': m['text']?.toString() ?? '',
                    'isUser': m['isUser'] == true,
                    'time': m['time']?.toString() ?? ''
                  }));
        });
      } catch (_) {
        setState(() => _messages.clear());
      }
    } else {
      setState(() => _messages.clear());
    }
  }

  Future<void> _addRoom() async {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final navigator = Navigator.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Room Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              decoration: const InputDecoration(labelText: 'Room ID'),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Room'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final id = idController.text.trim();
              final name = nameController.text.trim().isEmpty
                  ? id
                  : nameController.text.trim();
              if (id.isEmpty) return;
              final prefs = await SharedPreferences.getInstance();
              _rooms.add({'id': id, 'name': name});
              await prefs.setString('chat_rooms', jsonEncode(_rooms));
              setState(() {
                _currentRoomId = id;
                _currentRoomName = name;
              });
              await _saveMessages();
              navigator.pop();
              await _loadMessagesForCurrentRoom();
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'] as bool;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isUser ? Colors.green.shade100 : Colors.blue.shade50;
    final textColor = isUser ? Colors.green.shade900 : Colors.blue.shade900;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message['text'] as String,
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              message['time'] as String,
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentRoomName ?? 'Chat'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _addRoom,
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              final room = _rooms.firstWhere((r) => r['id'] == value);
              setState(() {
                _currentRoomId = room['id'];
                _currentRoomName = room['name'];
              });
              await _loadMessagesForCurrentRoom();
            },
            itemBuilder: (ctx) => _rooms
                .map((r) => PopupMenuItem(value: r['id'], child: Text(r['name'] ?? r['id']!)))
                .toList(),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentRoomId == null
                ? Center(
                    child: Text(
                      'Pilih atau buat room untuk mulai chat',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildBubble(_messages[index]);
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan untuk seller...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue.shade700,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _currentRoomId == null ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentRoomId = widget.initialRoomId;
    _currentRoomName = widget.initialRoomName;
    _loadRooms().then((_) async {
      if (_currentRoomId != null) {
        await _loadMessagesForCurrentRoom();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
