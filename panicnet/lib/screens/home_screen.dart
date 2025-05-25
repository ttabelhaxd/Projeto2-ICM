import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../services/hive_service.dart';
import '../services/image_service.dart';
import '../widgets/emergency_button.dart';
import 'gallery_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<HiveService>(
          create: (_) => HiveService(
              Hive.box('emergencyImages'), Hive.box('settings')),
        ),
        Provider<ImageService>(
          create: (context) => ImageService(context.read<HiveService>()),
        ),
        Provider<BluetoothService>(
          create: (_) => BluetoothService(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Emergency Sharing'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            const EmergencyButton(),
            Expanded(
              child: GalleryScreen(),
            ),
          ],
        ),
      ),
    );
  }
}