import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/gallery_screen.dart';
import 'services/bluetooth_service.dart';
import 'services/hive_service.dart';
import 'services/image_service.dart';
import 'services/shake_detector_service.dart';
import 'models/emergency_image.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initializeHive();

    runApp(
      MultiProvider(
        providers: [
          Provider(create: (_) => BluetoothService()),
          Provider(
            create: (_) => HiveService(
              Hive.box<EmergencyImage>('emergencyImages'),
              Hive.box('settings'),
            ),
          ),
          Provider(
            create: (context) => ImageService(
              context.read<HiveService>(),
            ),
          ),
          Provider(
            create: (context) => ShakeDetectorService(
              onShakeDetected: () => _handleShake(context),
            ),
          ),
        ],
        child: const EmergencySharingApp(),
      ),
    );
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Erro na inicialização: $e'),
          ),
        ),
      ),
    );
  }
}

Future<void> _initializeHive() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(EmergencyImageAdapter().typeId)) {
    Hive.registerAdapter(EmergencyImageAdapter());
  }
  await Hive.openBox<EmergencyImage>('emergencyImages');
  await Hive.openBox('settings');
}

Future<void> _handleShake(BuildContext context) async {
  if (!context.mounted) return;

  final image = await Provider.of<ImageService>(context, listen: false)
      .takeEmergencyPhoto();

  if (image != null && context.mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(emergencyImage: image),
      ),
    );
  }
}

class EmergencySharingApp extends StatelessWidget {
  const EmergencySharingApp({super.key});

  @override
  Widget build(BuildContext context) {
    Provider.of<ShakeDetectorService>(context, listen: false).startListening();

    return MaterialApp(
      title: 'Emergency Sharing',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
        '/gallery': (context) => const GalleryScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}