import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/image_service.dart';
import '../services/bluetooth_service.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final imageService = context.read<ImageService>();
    final bluetoothService = context.read<BluetoothService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tirar Foto de Emergência'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 100, color: Colors.red),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 15),
              ),
              child: const Text(
                'TIRAR FOTO',
                style: TextStyle(fontSize: 20),
              ),
              onPressed: () async {
                final image = await imageService.takeEmergencyPhoto();
                if (image != null) {
                  await bluetoothService.shareImage(image);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}