import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';

class ShakeDetectorService {
  static const double shakeThresholdGravity = 2.7;
  static const int shakeSlopTimeMS = 500;
  DateTime? _lastShakeTime;

  final Function() onShakeDetected;

  ShakeDetectorService({required this.onShakeDetected});

  void startListening() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      final double gForce = sqrt(event.x * event.x + event.y * event.y + event.z * event.z) / 9.81;
      final now = DateTime.now();

      if (gForce > shakeThresholdGravity) {
        if (_lastShakeTime == null ||
            now.difference(_lastShakeTime!) > Duration(milliseconds: shakeSlopTimeMS)) {
          _lastShakeTime = now;
          onShakeDetected();
        }
      }
    });
  }
}