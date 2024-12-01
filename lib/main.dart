import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fcai/notification_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  if (await NotificationHandler.getPermission()) {
    NotificationHandler.initialize();
  }
  NotificationHandler.handleForegroundNotification();
  NotificationHandler.handleBackgroundNotification();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Messaging',
      home: NotificationPage(),
    );
  }
}

class NotificationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Channels'),
      ),
      body: NotificationChannelList(),
    );
  }
}

class NotificationChannelList extends StatefulWidget {
  @override
  _NotificationChannelListState createState() =>
      _NotificationChannelListState();
}

class _NotificationChannelListState extends State<NotificationChannelList> {
  final List<String> channels = ['news', 'sports', 'weather'];
  final Map<String, bool> subscriptions = {};

  @override
  void initState() {
    super.initState();
    for (var channel in channels) {
      subscriptions[channel] = false;
    }
  }

  void toggleSubscription(String channel) async {
    if (subscriptions[channel]!) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(channel);
      print('Unsubscribed from $channel');
    } else {
      await FirebaseMessaging.instance.subscribeToTopic(channel);
      print('Subscribed to $channel');
    }
    setState(() {
      subscriptions[channel] = !subscriptions[channel]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: channels.length,
      itemBuilder: (context, index) {
        String channel = channels[index];
        return SwitchListTile(
          title: Text(channel),
          value: subscriptions[channel]!,
          onChanged: (value) {
            toggleSubscription(channel);
          },
        );
      },
    );
  }
}
