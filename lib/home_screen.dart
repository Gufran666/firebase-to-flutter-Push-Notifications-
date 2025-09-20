import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class HomeScreen extends StatefulWidget {
  final NotificationService notificationService;

  const HomeScreen({Key? key, required this.notificationService}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
    _loadSubscriptionState();
  }

  Future<void> _initFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final token = await messaging.getToken();
    print('FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.notification?.title}');
      if (message.notification != null) {
        widget.notificationService.showNotification(
          message.hashCode,
          message.notification!.title ?? 'Daily Motivation',
          message.notification!.body ?? 'No quote available.',
        );
      }
    });

    // Handle notification tap when app is in background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened: ${message.notification?.title}');
      Navigator.pushNamed(context, '/details', arguments: message.notification?.body);
    });

    // Check for initial message (app opened from terminated state)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null && message.notification != null) {
        Navigator.pushNamed(context, '/details', arguments: message.notification!.body);
      }
    });
  }

  Future<void> _loadSubscriptionState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSubscribed = prefs.getBool('isSubscribed') ?? false;
    });
  }

  Future<void> _toggleSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSubscribed = !_isSubscribed;
      prefs.setBool('isSubscribed', _isSubscribed);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSubscribed ? 'Subscribed to notifications!' : 'Unsubscribed from notifications.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Motivation'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Discipline is destiny.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _toggleSubscription,
              child: Text(_isSubscribed ? 'Unsubscribe' : 'Subscribe to Notifications'),
            ),
          ],
        ),
      ),
    );
  }
}