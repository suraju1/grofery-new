import 'package:hive_flutter/hive_flutter.dart';

part 'tiered_pricing.g.dart';

@HiveType(typeId: 12)
class TieredPricing {
  @HiveField(0)
  late int minQty;
  
  @HiveField(1)
  late double price;

  TieredPricing({required this.minQty, required this.price});

  TieredPricing.fromJson(Map<String, dynamic> json) {
    minQty = int.tryParse(json['min_qty'].toString()) ?? 0;
    price = double.tryParse(json['price'].toString()) ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['min_qty'] = minQty.toString();
    data['price'] = price.toString();
    return data;
  }
}
