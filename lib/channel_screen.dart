import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'chat_screen.dart';
import 'notification_handler.dart';
import 'sign_in_screen.dart';

class ChannelScreen extends StatefulWidget {
  @override
  _ChannelScreenState createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  final CollectionReference _channels = FirebaseFirestore.instance.collection('channels');
  final DatabaseReference chatRef = FirebaseDatabase.instance.ref();
  late String _userId;

  @override
  void initState(){
    super.initState();
    _initNotifications();
    _getUserId();
  }

  Future<void> _initNotifications() async {
    if (await NotificationHandler.getPermission()) {
    NotificationHandler.initialize();
    }
    NotificationHandler.handleForegroundNotification();
    NotificationHandler.handleBackgroundNotification();
  }

  void _getUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Hides the back arrow
        title: Text('Channels'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddChannelDialog,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _channels.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var channels = snapshot.data!.docs;
          return ListView.builder(
            itemCount: channels.length,
            itemBuilder: (context, index) {
              var channel = channels[index];
              List<dynamic> subscribers = channel['subscribers'] ?? [];
              bool isSubscribed = subscribers.contains(_userId);
              if (isSubscribed) {
                FirebaseMessaging.instance.subscribeToTopic(channel['name']);
              }

              return ListTile(
                contentPadding: EdgeInsets.only(left: 18),
                title: Text(channel['name']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSubscribed)
                      IconButton(
                        icon: Icon(Icons.chat),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                channelId: channel.id,
                                channelName: channel['name'],
                              ),
                            ),
                          );
                        },
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSubscribed ? Colors.red : Colors.green,
                        minimumSize: Size(80, 36),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        _subscribeToChannel(channel.id, channel['name'], isSubscribed);
                      },
                      child: Text(
                        isSubscribed ? 'Unsub' : 'Sub',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.more_vert),
                      onPressed: () {
                        _showChannelOptions(channel.id, channel['name']);
                      },
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddChannelDialog() {
    final TextEditingController _channelController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create New Channel'),
          content: TextField(
            controller: _channelController,
            decoration: InputDecoration(hintText: 'Enter Channel Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _createChannel(_channelController.text.trim());
                Navigator.pop(context);
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _createChannel(String channelName) async {
    if (channelName.isNotEmpty) {
      await _channels.add({
        'name': channelName,
        'subscribers': [],
      });
    }
  }

  Future<void> _subscribeToChannel(String channelId, String channelName, bool isSubscribed) async {
    DocumentReference channelRef = _channels.doc(channelId);
    if (isSubscribed) {
      await channelRef.update({
        'subscribers': FieldValue.arrayRemove([_userId]),
      });
      await FirebaseMessaging.instance.unsubscribeFromTopic(channelName);
    } else {
      await channelRef.update({
        'subscribers': FieldValue.arrayUnion([_userId]),
      });
      await FirebaseMessaging.instance.subscribeToTopic(channelName);
    }
  }

  void _showChannelOptions(String channelId, String channelName) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Modify Name'),
              onTap: () {
                Navigator.pop(context);
                _showModifyChannelDialog(channelId, channelName);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteChannel(channelId, channelName);
              },
            ),
          ],
        );
      },
    );
  }

  void _showModifyChannelDialog(String channelId, String currentName) {
    final TextEditingController _channelController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modify Name'),
          content: TextField(
            controller: _channelController,
            decoration: InputDecoration(hintText: 'Enter New Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_channelController.text.trim().isNotEmpty) {
                  await _channels.doc(channelId).update({
                    'name': _channelController.text.trim(),
                  });
                }
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteChannel(String channelId, String channelName) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(channelName);
    await _channels.doc(channelId).delete();
    await chatRef.child('chatRooms/$channelId').remove();
  }

  void _signOut() async {
    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut(); // Sign out from Google
      }
    } catch (e) {
      print('Error signing out: $e');
    }
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),
    );
  }
}
