// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomerAdapter extends TypeAdapter<Customer> {
  @override
  final int typeId = 1;

  @override
  Customer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Customer(
      customerId: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      details: fields[3] as String,
      guidelines: fields[4] as String,
      engagementFrequencyDays: fields[5] as int,
      nextEngagementDate: fields[6] as DateTime,
      lastEngagementDate: fields[7] as DateTime,
      hasActiveDraft: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Customer obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.customerId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.details)
      ..writeByte(4)
      ..write(obj.guidelines)
      ..writeByte(5)
      ..write(obj.engagementFrequencyDays)
      ..writeByte(6)
      ..write(obj.nextEngagementDate)
      ..writeByte(7)
      ..write(obj.lastEngagementDate)
      ..writeByte(8)
      ..write(obj.hasActiveDraft);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
