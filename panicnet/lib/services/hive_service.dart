import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/emergency_image.dart';

class HiveService with ChangeNotifier {
  final Box<EmergencyImage> imageBox;
  final Box settingsBox;

  HiveService(this.imageBox, this.settingsBox);

  Future<void> saveImage(EmergencyImage image) async {
    await imageBox.put(image.id, image);
    notifyListeners();
  }

  List<EmergencyImage> getAllImages() {
    return imageBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  String getUsername() {
    return settingsBox.get('username', defaultValue: 'Usuário Local');
  }

  Future<void> setUsername(String username) async {
    await settingsBox.put('username', username);
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await imageBox.clear();
    notifyListeners();
  }
}