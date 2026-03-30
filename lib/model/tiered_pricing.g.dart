// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tiered_pricing.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TieredPricingAdapter extends TypeAdapter<TieredPricing> {
  @override
  final int typeId = 12;

  @override
  TieredPricing read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TieredPricing(
      minQty: fields[0] as int,
      price: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, TieredPricing obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.minQty)
      ..writeByte(1)
      ..write(obj.price);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TieredPricingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
