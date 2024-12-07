import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatScreen extends StatefulWidget {
  final String channelId;
  final String channelName;

  ChatScreen({required this.channelId, required this.channelName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseReference _chatRef = FirebaseDatabase.instance.ref();
  late String _userName;
  List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController(); // Add ScrollController

  void _initializeUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userName = user.displayName ?? 'Anonymous'; // Use displayName or a fallback
    }
  }

  @override
  void initState() {
    super.initState();
    _chatRef.child('chatRooms/${widget.channelId}/messages').onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _messages = data.entries
              .map((entry) => Map<String, dynamic>.from(entry.value))
              .toList();
        });
        // Scroll to the bottom after new messages are added
        _scrollToBottom();
      }
    });
    _initializeUserName();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the controller when the screen is disposed
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channelName), // Use channel name as title
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // Set the ScrollController
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                // sort messages by timestamp
                _messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
                return ListTile(
                  title: Text(message['text']),
                  subtitle: Text('Sender: ${message['sender']}'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: 'Enter message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatRef.child('chatRooms/${widget.channelId}/messages').push().set({
        'sender': _userName,
        'text': _messageController.text,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _messageController.clear();
      _scrollToBottom();
    }
  }
}
