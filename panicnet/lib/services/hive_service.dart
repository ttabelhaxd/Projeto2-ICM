import 'package:hive/hive.dart';
import '../models/emergency_image.dart';

class HiveService {
  final Box<EmergencyImage> imageBox;
  final Box settingsBox;

  HiveService(this.imageBox, this.settingsBox);

  Future<void> saveImage(EmergencyImage image) async {
    await imageBox.put(image.id, image);
  }

  List<EmergencyImage> getAllImages() {
    return imageBox.values.toList();
  }

  String getUsername() {
    return settingsBox.get('username', defaultValue: 'UsuarioLocal');
  }

  Future<void> setUsername(String username) async {
    await settingsBox.put('username', username);
  }
}