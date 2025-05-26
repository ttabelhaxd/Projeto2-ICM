import 'package:image_picker/image_picker.dart';
import '../models/emergency_image.dart';
import 'hive_service.dart';

class ImageService {
  final HiveService hiveService;
  final ImagePicker _picker = ImagePicker();

  ImageService(this.hiveService);

  Future<EmergencyImage?> takeEmergencyPhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
    );

    if (image != null) {
      final emergencyImage = EmergencyImage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: image.path,
        username: hiveService.getUsername(),
      );

      await hiveService.saveImage(emergencyImage);
      return emergencyImage;
    }
    return null;
  }
}