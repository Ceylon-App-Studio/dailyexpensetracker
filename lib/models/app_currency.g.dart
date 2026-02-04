// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_currency.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppCurrencyAdapter extends TypeAdapter<AppCurrency> {
  @override
  final int typeId = 4;

  @override
  AppCurrency read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppCurrency(
      code: fields[0] as String,
      name: fields[1] as String,
      symbol: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppCurrency obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.code)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.symbol);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppCurrencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
