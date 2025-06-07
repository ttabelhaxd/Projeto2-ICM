import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:panicnet/models/panic_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';

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
  late String _currentConversationKey;
  List<PanicImage> _currentConversationImages = [];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  StreamSubscription<AccelerometerEvent>? _accelerometerStreamSubscription;
  bool _cameraOpen = false;

  @override
  void initState() {
    super.initState();
    _currentConversationKey = PanicImage.getConversationKey(user, widget.device);
    _initializeLocalNotifications();
    _setupPayloadListener();
    _loadCurrentConversationImages();
    _initializeCamera();
    _setupShakeDetection();
  }

  void _loadCurrentConversationImages() async {
    List<String>? imagesJson = _box.get(_currentConversationKey);
    if (imagesJson != null) {
      print("Carregando ${imagesJson.length} imagens da conversa com ${widget.device}");
      setState(() {
        _currentConversationImages = imagesJson
            .map((json) => PanicImage.fromJson(jsonDecode(json)))
            .toList();
      });
    }
  }

  void _setupShakeDetection() {
    _accelerometerStreamSubscription =
        accelerometerEventStream().listen((event) {
          final gestureProvider = Provider.of<GestureProvider>(context, listen: false);
          gestureProvider.updateAccelerometerData(event);

          if (!_cameraOpen) {
            gestureProvider.detectShake(event);
            if (gestureProvider.isShaking) {
              _openCamera();
              gestureProvider.resetValues();
            }
          }
        });
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

  void _initializeCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    _cameraController = CameraController(backCamera, ResolutionPreset.medium);
    await _cameraController.initialize();
  }

  void _setupPayloadListener() {
    Nearby().acceptConnection(
      widget.endpointId,
      onPayLoadRecieved: (endid, payload) async {
        if (payload.type == PayloadType.BYTES) {
          try {
            String receivedData = utf8.decode(payload.bytes!);
            print("Dados recebidos: $receivedData");

            var data = jsonDecode(receivedData);

            if (data['receiver'] == user) {
              var panicImage = PanicImage.fromJson(data);

              setState(() {
                _currentConversationImages.add(panicImage);
                _saveCurrentConversationImages();
              });

              _showNotification(
                'Alerta de ${panicImage.sender}',
                panicImage.message,
              );
            }
          } catch (e) {
            print("Erro ao processar dados recebidos: $e");
          }
        }
      },
      onPayloadTransferUpdate: (endid, payloadTransferUpdate) {
        print("Status do envio: ${payloadTransferUpdate.status}");
        print("Bytes transferidos: ${payloadTransferUpdate.bytesTransferred}");
      },
    );
  }

  Future<void> _captureAndSendImage() async {
    try {
      final XFile? image = await _cameraController.takePicture();
      if (image == null) return;

      Uint8List imageBytes = await image.readAsBytes();
      Position position = await Geolocator.getCurrentPosition();

      String location = "${position.latitude},${position.longitude}";
      String message = "HELP!!! I'm here: $location";

      var panicImage = PanicImage(
        imageBytes: imageBytes,
        sender: user,
        receiver: widget.device, // Usar o dispositivo atual como receptor
        timestamp: DateTime.now(),
        location: location,
        message: message,
      );

      var payload = {
        'imageBytes': base64Encode(imageBytes),
        'sender': user,
        'receiver': widget.device, // Usar o dispositivo atual como receptor
        'timestamp': panicImage.timestamp.toIso8601String(),
        'location': location,
        'message': message,
      };

      String jsonData = jsonEncode(payload);
      print("Preparando para enviar payload para ${widget.device}...");

      try {
        await Nearby().sendBytesPayload(widget.endpointId, utf8.encode(jsonData));
        print("Payload enviado com sucesso para ${widget.endpointId}");
      } catch (e) {
        print("Erro ao enviar payload: $e");
      }

      setState(() {
        _currentConversationImages.add(panicImage);
        _saveCurrentConversationImages();
      });

    } catch (e) {
      print("Erro ao capturar e enviar imagem: $e");
    }
  }

  void _saveCurrentConversationImages() {
    List<String> imagesJson = _currentConversationImages
        .map((img) => jsonEncode(img.toJson()))
        .toList();
    _box.put(_currentConversationKey, imagesJson);
    print("Imagens salvas para conversa com ${widget.device}: ${imagesJson.length} itens");
  }

  void _openCamera() {
    setState(() => _cameraOpen = true);
    final gestureProvider = Provider.of<GestureProvider>(context, listen: false);
    gestureProvider.setShakeDetectionEnabled(false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Foto de Emergência"),
        content: CameraPreview(_cameraController),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _closeCamera();
            },
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _captureAndSendImage().then((_) => _closeCamera());
            },
            child: const Text("Enviar Alerta"),
          ),
        ],
      ),
    ).then((_) => _closeCamera());
  }

  void _closeCamera() {
    setState(() => _cameraOpen = false);
    final gestureProvider = Provider.of<GestureProvider>(context, listen: false);
    gestureProvider.setShakeDetectionEnabled(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Connection with ${widget.device}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentConversationImages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum alerta compartilhado ainda',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              reverse: true,
              itemCount: _currentConversationImages.length,
              itemBuilder: (context, index) {
                final image = _currentConversationImages[_currentConversationImages.length - 1 - index];
                return _buildMessageBubble(image);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton(
              onPressed: _openCamera,
              backgroundColor: Colors.red,
              child: const Icon(Icons.camera_alt),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(PanicImage image) {
    final isMe = image.sender == user;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(image.sender, style: const TextStyle(fontWeight: FontWeight.bold)),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: Image.memory(
              image.imageBytes,
              fit: BoxFit.contain,
            ),
          ),
          Text(DateFormat('HH:mm').format(image.timestamp)),
          if (!isMe) Text(image.message),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _accelerometerStreamSubscription?.cancel();
    _cameraController.dispose();
    super.dispose();
  }
}