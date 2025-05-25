// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emergency_image.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmergencyImageAdapter extends TypeAdapter<EmergencyImage> {
  @override
  final int typeId = 0;

  @override
  EmergencyImage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmergencyImage(
      id: fields[0] as String,
      imagePath: fields[1] as String,
      username: fields[3] as String,
      location: fields[4] as String?,
      synced: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, EmergencyImage obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.username)
      ..writeByte(4)
      ..write(obj.location)
      ..writeByte(5)
      ..write(obj.synced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyImageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
