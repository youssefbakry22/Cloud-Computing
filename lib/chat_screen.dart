import 'package:flutter/material.dart';
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
  List<Map<String, dynamic>> _messages = [];

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
      }
    });
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
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Text(message['text']),
                  subtitle: Text('Sender: ${message['senderId']}'),
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
        'senderId': 'user123', // Replace with actual user ID
        'text': _messageController.text,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _messageController.clear();
    }
  }

}
