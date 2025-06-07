import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class GestureProvider extends ChangeNotifier {
  static const double threshold = 10;
  static const int shakeCountThreshold = 3;
  static const Duration shakeTimeout = Duration(milliseconds: 1000);

  double _lastX = 0;
  double _lastY = 0;
  double _lastZ = 0;
  int _shakeCount = 0;
  DateTime? _lastShakeTime;
  bool _isShaking = false;
  bool _shakeDetectionEnabled = true;

  // Public getters
  double get x => _lastX;
  double get y => _lastY;
  double get z => _lastZ;
  bool get isShaking => _isShaking;
  int get shakeCount => _shakeCount;

  void updateAccelerometerData(AccelerometerEvent event) {
    if (!_shakeDetectionEnabled) return;

    final now = DateTime.now();
    final double currentX = event.x;
    final double currentY = event.y;
    final double currentZ = event.z;

    // Calculate acceleration difference
    final double deltaX = (currentX - _lastX).abs();
    final double deltaY = (currentY - _lastY).abs();
    final double deltaZ = (currentZ - _lastZ).abs();

    _lastX = currentX;
    _lastY = currentY;
    _lastZ = currentZ;

    // Reset count if too much time passed
    if (_lastShakeTime != null && now.difference(_lastShakeTime!) > shakeTimeout) {
      _shakeCount = 0;
    }

    // Check if shake detected
    if (deltaX > threshold || deltaY > threshold || deltaZ > threshold) {
      _shakeCount++;
      _lastShakeTime = now;

      if (_shakeCount >= shakeCountThreshold && !_isShaking) {
        _isShaking = true;
        notifyListeners();
        _resetAfterDelay();
      }
    }
  }

  void detectShake(AccelerometerEvent event) {
    updateAccelerometerData(event);
  }

  void _resetAfterDelay() {
    Future.delayed(shakeTimeout, () {
      resetValues();
    });
  }

  void resetValues() {
    _isShaking = false;
    _shakeCount = 0;
    notifyListeners();
  }

  void setShakeDetectionEnabled(bool enabled) {
    _shakeDetectionEnabled = enabled;
    if (!enabled) {
      resetValues();
    }
  }
}