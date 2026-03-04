// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'advisor.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AdvisorAdapter extends TypeAdapter<Advisor> {
  @override
  final int typeId = 0;

  @override
  Advisor read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Advisor(
      uid: fields[0] as String,
      name: fields[1] as String,
      firmName: fields[2] as String,
      email: fields[3] as String,
      aiCapability: fields[4] as String,
      isExpressiveAiEnabled: fields[5] as bool,
      isMultimodalAiEnabled: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Advisor obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.firmName)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.aiCapability)
      ..writeByte(5)
      ..write(obj.isExpressiveAiEnabled)
      ..writeByte(6)
      ..write(obj.isMultimodalAiEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdvisorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
