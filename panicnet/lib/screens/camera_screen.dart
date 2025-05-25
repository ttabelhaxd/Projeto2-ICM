import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/emergency_image.dart';
import '../services/bluetooth_service.dart';
import 'dart:io';

class CameraScreen extends StatelessWidget {
  final EmergencyImage emergencyImage;

  const CameraScreen({
    super.key,
    required this.emergencyImage,
  });

  @override
  Widget build(BuildContext context) {
    final bluetoothService = Provider.of<BluetoothService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Emergência'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Image.file(File(emergencyImage.imagePath)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  await bluetoothService.shareImage(emergencyImage);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  'ENVIAR PARA DISPOSITIVOS PRÓXIMOS',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}