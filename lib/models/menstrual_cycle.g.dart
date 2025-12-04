// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menstrual_cycle.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MenstrualCycleAdapter extends TypeAdapter<MenstrualCycle> {
  @override
  final int typeId = 1;

  @override
  MenstrualCycle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MenstrualCycle(
      startDate: fields[0] as DateTime,
      endDate: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MenstrualCycle obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.startDate)
      ..writeByte(1)
      ..write(obj.endDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenstrualCycleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
