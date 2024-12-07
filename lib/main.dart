import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'notification_handler.dart';
import 'channel_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  if (await NotificationHandler.getPermission()) {
    NotificationHandler.initialize();
  }
  NotificationHandler.handleForegroundNotification();
  NotificationHandler.handleBackgroundNotification();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Room',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: ChannelScreen(),
    );
  }
}