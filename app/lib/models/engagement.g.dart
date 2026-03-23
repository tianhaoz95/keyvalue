// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'engagement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EngagementAdapter extends TypeAdapter<Engagement> {
  @override
  final int typeId = 3;

  @override
  Engagement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Engagement(
      engagementId: fields[0] as String,
      status: fields[1] as EngagementStatus,
      draftMessage: fields[2] as String,
      sentMessage: fields[3] as String,
      customerResponse: fields[4] as String,
      pointsOfInterest: (fields[5] as List).cast<String>(),
      updatedDetailsDiff: fields[6] as String,
      changeSummary: fields[9] as String,
      createdAt: fields[7] as DateTime,
      aiSource: fields[8] as AiSource,
    );
  }

  @override
  void write(BinaryWriter writer, Engagement obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.engagementId)
      ..writeByte(1)
      ..write(obj.status)
      ..writeByte(2)
      ..write(obj.draftMessage)
      ..writeByte(3)
      ..write(obj.sentMessage)
      ..writeByte(4)
      ..write(obj.customerResponse)
      ..writeByte(5)
      ..write(obj.pointsOfInterest)
      ..writeByte(6)
      ..write(obj.updatedDetailsDiff)
      ..writeByte(9)
      ..write(obj.changeSummary)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.aiSource);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EngagementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EngagementStatusAdapter extends TypeAdapter<EngagementStatus> {
  @override
  final int typeId = 2;

  @override
  EngagementStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EngagementStatus.draft;
      case 1:
        return EngagementStatus.pendingReview;
      case 2:
        return EngagementStatus.sent;
      case 3:
        return EngagementStatus.received;
      case 4:
        return EngagementStatus.completed;
      default:
        return EngagementStatus.draft;
    }
  }

  @override
  void write(BinaryWriter writer, EngagementStatus obj) {
    switch (obj) {
      case EngagementStatus.draft:
        writer.writeByte(0);
        break;
      case EngagementStatus.pendingReview:
        writer.writeByte(1);
        break;
      case EngagementStatus.sent:
        writer.writeByte(2);
        break;
      case EngagementStatus.received:
        writer.writeByte(3);
        break;
      case EngagementStatus.completed:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EngagementStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AiSourceAdapter extends TypeAdapter<AiSource> {
  @override
  final int typeId = 4;

  @override
  AiSource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AiSource.onDevice;
      case 1:
        return AiSource.cloud;
      case 2:
        return AiSource.unknown;
      default:
        return AiSource.onDevice;
    }
  }

  @override
  void write(BinaryWriter writer, AiSource obj) {
    switch (obj) {
      case AiSource.onDevice:
        writer.writeByte(0);
        break;
      case AiSource.cloud:
        writer.writeByte(1);
        break;
      case AiSource.unknown:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
