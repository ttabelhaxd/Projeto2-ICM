import 'dart:convert';
import 'dart:typed_data';
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
  bool _isConnected = false;

  bool _isImage(Uint8List bytes) {
    return bytes.length >= 2 &&
        bytes[0] == 0xFF &&
        (bytes[1] == 0xD8 || // JPEG
            bytes[1] == 0x89 || // PNG
            bytes[1] == 0x47 || // GIF
            bytes[1] == 0x49 || // TIFF
            bytes[1] == 0x42); // BMP
  }

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

  void _setupGlobalReceiver() async {
    try {
      await Nearby().stopAllEndpoints();
      await Nearby().acceptConnection(
        '',
        onPayLoadRecieved: (endid, payload) async {
          if (payload.type == PayloadType.BYTES) {
            try {
              String receivedData = utf8.decode(payload.bytes!);
              var data = jsonDecode(receivedData);

              if (data['imageBytes'] != null) {
                var panicImage = PanicImage.fromJson(data);
                String currentUser = _box.get('user', defaultValue: '');

                if (panicImage.receiver == currentUser) {
                  String conversationKey = PanicImage.getConversationKey(
                      panicImage.sender, panicImage.receiver);

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
            } catch (e) {
              print('Error processing payload: $e');
              // Fallback para formato antigo (apenas imagem)
              if (_isImage(payload.bytes!)) {
                var panicImage = PanicImage(
                  imageBytes: payload.bytes!,
                  sender: 'Unknown',
                  receiver: _box.get('user', defaultValue: ''),
                  timestamp: DateTime.now(),
                  message: "Emergency photo received",
                );

                String conversationKey = PanicImage.getConversationKey(
                    panicImage.sender, panicImage.receiver);

                List<String> currentConversation =
                _box.get(conversationKey, defaultValue: []);
                currentConversation.add(jsonEncode(panicImage.toJson()));
                await _box.put(conversationKey, currentConversation);

                _showNotification(
                  'Emergency Photo Received',
                  'New emergency photo received',
                );
              }
            }
          }
        },
      );
      _isConnected = true;
    } catch (e) {
      print('Error setting up receiver: $e');
      Future.delayed(const Duration(seconds: 5), () => _setupGlobalReceiver());
    }
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
  void dispose() {
    Nearby().stopAllEndpoints();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}