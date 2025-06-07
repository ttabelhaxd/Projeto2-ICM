import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class GestureProvider extends ChangeNotifier {
  double x = 0;
  double y = 0;
  double z = 0;
  bool isShaking = false;
  int shakeCount = 0;
  bool _shakeDetectionEnabled = true;

  static const double THRESHOLD = 25;

  void updateAccelerometerData(AccelerometerEvent event) {
    x = event.x;
    y = event.y;
    z = event.z;
  }

  void detectShake(AccelerometerEvent event) {
    if (!_shakeDetectionEnabled) return;

    if (event.x.abs() > THRESHOLD) {
      shakeCount++;
      if (!isShaking && shakeCount > 2) {
        isShaking = true;
        shakeCount = 0;
        notifyListeners();
      }
    }
  }

  void setShakeDetectionEnabled(bool enabled) {
    _shakeDetectionEnabled = enabled;
    if (!enabled) {
      resetValues();
    }
  }

  void resetValues() {
    x = 0;
    y = 0;
    z = 0;
    isShaking = false;
    shakeCount = 0;
    notifyListeners();
  }
}