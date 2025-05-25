import 'package:hive/hive.dart';

part 'emergency_image.g.dart';

@HiveType(typeId: 0)
class EmergencyImage {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String imagePath;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String username;

  @HiveField(4)
  final String? location;

  @HiveField(5)
  bool synced;

  EmergencyImage({
    required this.id,
    required this.imagePath,
    required this.username,
    this.location,
    this.synced = false,
  }) : timestamp = DateTime.now();
}