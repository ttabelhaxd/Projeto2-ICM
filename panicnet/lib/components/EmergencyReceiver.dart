import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:panicnet/models/panic_image.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class EmergencyReceiver extends StatefulWidget {
  final Widget child;

  const EmergencyReceiver({super.key, required this.child});

  @override
  State<EmergencyReceiver> createState() => _EmergencyReceiverState();
}

class _EmergencyReceiverState extends State<EmergencyReceiver> {
  final _box = Hive.box('panicnet');
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _setupGlobalReceiver();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _setupGlobalReceiver() {
    Nearby().acceptConnection(
      '',
      onPayLoadRecieved: (endid, payload) async {
        if (payload.type == PayloadType.BYTES) {
          String receivedData = utf8.decode(payload.bytes!);
          var data = jsonDecode(receivedData);

          if (data['receiver'] != null) {
            var panicImage = PanicImage.fromJson(data);
            String currentUser = _box.get('user');

            if (panicImage.receiver == currentUser) {
              String conversationKey = PanicImage.getConversationKey(
                  panicImage.sender,
                  panicImage.receiver
              );

              List<String> currentConversation =
              _box.get(conversationKey, defaultValue: []);
              currentConversation.add(jsonEncode(panicImage.toJson()));
              await _box.put(conversationKey, currentConversation);

              _showNotification(
                'Alerta de ${panicImage.sender}',
                panicImage.message,
              );
            }
          }
        }
      },
    );
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'panicnet_channel',
      'PanicNet Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, title, body, platformChannelSpecifics);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}