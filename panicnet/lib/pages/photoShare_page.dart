import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:panicnet/models/panic_image.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:camera/camera.dart';
import '../providers/gesture_provider.dart';

class PhotoSharePage extends StatefulWidget {
  final String device;
  final String endpointId;

  const PhotoSharePage({
    super.key,
    required this.device,
    required this.endpointId,
  });

  @override
  _PhotoSharePageState createState() => _PhotoSharePageState();
}

class _PhotoSharePageState extends State<PhotoSharePage> {
  final _box = Hive.box('panicnet');
  late String user = _box.get('user');
  late CameraController _cameraController;
  List<PanicImage> _images = [];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  late StreamSubscription<AccelerometerEvent> _accelerometerStreamSubscription;
  bool _cameraOpen = false;

  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
    _setupPayloadListener();
    _loadImages();
    _initializeCamera();
    _setupShakeDetection();
  }

  @override
  void dispose() {
    _accelerometerStreamSubscription.cancel();
    _cameraController.dispose();
    super.dispose();
  }

  void _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
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

  void _setupShakeDetection() {
    _accelerometerStreamSubscription =
        accelerometerEventStream().listen((event) {
          if (event.x.abs() > 1) {
            final gestureProvider =
            Provider.of<GestureProvider>(context, listen: false);
            gestureProvider.updateAccelerometerData(event);
            gestureProvider.detectShake(event);

            if (gestureProvider.isShaking && !_cameraOpen) {
              _openCamera();
            }
          }
        });
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.first;
    _cameraController = CameraController(backCamera, ResolutionPreset.high);
    await _cameraController.initialize();
  }

  void _setupPayloadListener() {
    try {
      Nearby().acceptConnection(
        widget.endpointId,
        onPayLoadRecieved: (endid, payload) async {
          if (payload.type == PayloadType.BYTES) {
            try {
              // Check if it's an image directly (like in chatPage)
              if (_isImage(payload.bytes!)) {
                final panicImage = PanicImage(
                  imageBytes: payload.bytes!,
                  sender: widget.device,
                  receiver: user,
                  timestamp: DateTime.now(),
                  location: "Unknown",
                  message: "Photo received",
                );

                setState(() {
                  _images.add(panicImage);
                  _saveImages();
                });
                _showNotification(widget.device, "Photo received");
              }
            } catch (e) {
              print("Error processing payload: $e");
            }
          }
        },
        onPayloadTransferUpdate: (endid, payloadTransferUpdate) {},
      );
    } catch (exception) {
      print(exception);
    }
  }

  bool _isImage(Uint8List bytes) {
    return bytes.length >= 2 &&
        bytes[0] == 0xFF &&
        (bytes[1] == 0xD8 || // JPEG
            bytes[1] == 0x89 || // PNG
            bytes[1] == 0x47 || // GIF
            bytes[1] == 0x49 || // TIFF
            bytes[1] == 0x42); // BMP
  }

  void _openCamera() {
    if (!_cameraController.value.isInitialized) {
      return;
    }

    setState(() => _cameraOpen = true);
    final gestureProvider = Provider.of<GestureProvider>(context, listen: false);
    gestureProvider.resetValues();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emergency Photo"),
        content: CameraPreview(_cameraController),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _closeCamera();
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _captureAndSendImage().then((_) => _closeCamera());
            },
            child: const Text("Send"),
          ),
        ],
      ),
    ).then((_) => _closeCamera());
  }

  void _closeCamera() {
    setState(() => _cameraOpen = false);
  }

  Future<void> _captureAndSendImage() async {
    try {
      final XFile? image = await _cameraController.takePicture();
      if (image == null) return;

      Uint8List imageBytes = await image.readAsBytes();
      Nearby().sendBytesPayload(widget.endpointId, imageBytes);

      final panicImage = PanicImage(
        imageBytes: imageBytes,
        sender: user,
        receiver: widget.device,
        timestamp: DateTime.now(),
        location: "Unknown",
        message: "Emergency photo",
      );

      setState(() {
        _images.add(panicImage);
        _saveImages();
      });
    } catch (e) {
      print("Error capturing and sending image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send photo")),
      );
    }
  }

  void _saveImages() {
    String conversationKey = PanicImage.getConversationKey(user, widget.device);
    List<String> imagesJson = _images
        .map((img) => jsonEncode(img.toJson()))
        .toList();
    _box.put(conversationKey, imagesJson);
  }

  Future<void> _loadImages() async {
    String conversationKey = PanicImage.getConversationKey(user, widget.device);
    List<String>? imagesJson = _box.get(conversationKey);
    if (imagesJson != null) {
      setState(() {
        _images = imagesJson
            .map((json) => PanicImage.fromJson(jsonDecode(json)))
            .toList();
      });
    }
  }

  void _clearHistory() {
    String conversationKey = PanicImage.getConversationKey(user, widget.device);
    _box.delete(conversationKey);
    setState(() {
      _images.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Photos with ${widget.device}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _images.isEmpty
                ? Center(
              child: Text(
                'No photos exchanged yet',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              reverse: true,
              itemCount: _images.length,
              itemBuilder: (context, index) {
                final image = _images[_images.length - 1 - index];
                return _buildImageItem(image);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton(
              child: const Icon(Icons.camera_alt),
              onPressed: _openCamera,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem(PanicImage image) {
    final isMe = image.sender == user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6.0,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.memory(
                  image.imageBytes,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                isMe ? 'You' : image.sender,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}