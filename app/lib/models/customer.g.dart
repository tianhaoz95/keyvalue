// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EngagementScheduleAdapter extends TypeAdapter<EngagementSchedule> {
  @override
  final int typeId = 4;

  @override
  EngagementSchedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EngagementSchedule(
      scheduleId: fields[0] as String,
      startDate: fields[1] as DateTime,
      endDate: fields[2] as DateTime?,
      cadenceValue: fields[3] as int,
      cadencePeriod: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EngagementSchedule obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.scheduleId)
      ..writeByte(1)
      ..write(obj.startDate)
      ..writeByte(2)
      ..write(obj.endDate)
      ..writeByte(3)
      ..write(obj.cadenceValue)
      ..writeByte(4)
      ..write(obj.cadencePeriod);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EngagementScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
      occupation: fields[9] as String,
      phoneNumber: fields[10] as String,
      address: fields[11] as String,
      cadenceValue: fields[13] as int,
      cadencePeriod: fields[14] as String,
      schedules: (fields[15] as List).cast<EngagementSchedule>(),
      proposedDetails: fields[16] as String?,
      proposedGuidelines: fields[17] as String?,
      proposedDetailsSummary: fields[18] as String?,
      proposedGuidelinesSummary: fields[19] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Customer obj) {
    writer
      ..writeByte(19)
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
      ..write(obj.hasActiveDraft)
      ..writeByte(9)
      ..write(obj.occupation)
      ..writeByte(10)
      ..write(obj.phoneNumber)
      ..writeByte(11)
      ..write(obj.address)
      ..writeByte(13)
      ..write(obj.cadenceValue)
      ..writeByte(14)
      ..write(obj.cadencePeriod)
      ..writeByte(15)
      ..write(obj.schedules)
      ..writeByte(16)
      ..write(obj.proposedDetails)
      ..writeByte(17)
      ..write(obj.proposedGuidelines)
      ..writeByte(18)
      ..write(obj.proposedDetailsSummary)
      ..writeByte(19)
      ..write(obj.proposedGuidelinesSummary);
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
