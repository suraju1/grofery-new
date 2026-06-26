import '../../../model/tiered_pricing.dart';

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return double.tryParse(value)?.toInt() ?? int.tryParse(value) ?? 0;
  return 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class WishlistProductModel {
  bool? success;
  String? message;
  WishlistData? data;

  WishlistProductModel({this.success, this.message, this.data});

  WishlistProductModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? WishlistData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class WishlistData {
  int? id;
  String? title;
  String? slug;
  int? itemsCount;
  List<WishlistProductItems>? items;
  String? createdAt;
  String? updatedAt;

  WishlistData(
      {this.id,
      this.title,
      this.slug,
      this.itemsCount,
      this.items,
      this.createdAt,
      this.updatedAt});

  WishlistData.fromJson(Map<String, dynamic> json) {
    id = _toInt(json['id']);
    title = json['title'];
    slug = json['slug'];
    itemsCount = _toInt(json['items_count']);
    if (json['items'] != null) {
      items = <WishlistProductItems>[];
      json['items'].forEach((v) {
        items!.add(WishlistProductItems.fromJson(v));
      });
    }
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['slug'] = slug;
    data['items_count'] = itemsCount;
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class WishlistProductItems {
  int? id;
  int? wishlistId;
  Product? product;
  Variant? variant;
  Store? store;
  String? createdAt;
  String? updatedAt;

  WishlistProductItems(
      {this.id,
      this.wishlistId,
      this.product,
      this.variant,
      this.store,
      this.createdAt,
      this.updatedAt});

  WishlistProductItems.fromJson(Map<String, dynamic> json) {
    id = _toInt(json['id']);
    wishlistId = _toInt(json['wishlist_id']);
    product =
        json['product'] != null ? Product.fromJson(json['product']) : null;
    variant =
        json['variant'] != null ? Variant.fromJson(json['variant']) : null;
    store = json['store'] != null ? Store.fromJson(json['store']) : null;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['wishlist_id'] = wishlistId;
    if (product != null) {
      data['product'] = product!.toJson();
    }
    if (variant != null) {
      data['variant'] = variant!.toJson();
    }
    if (store != null) {
      data['store'] = store!.toJson();
    }
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Product {
  int? id;
  String? title;
  String? slug;
  String? image;
  int? minimumOrderQuantity;
  int? quantityStepSize;
  int? totalAllowedQuantity;
  String? shortDescription;
  String? estimatedDeliveryTime;
  String? imageFit;
  StoreStatus? storeStatus;
  double? ratings;
  int? ratingCount;
  bool? quickDeliveryAvailable;

  Product(
      {this.id,
      this.title,
      this.slug,
      this.image,
      this.minimumOrderQuantity,
      this.quantityStepSize,
      this.totalAllowedQuantity,
      this.shortDescription,
      this.estimatedDeliveryTime,
      this.imageFit,
      this.storeStatus,
      this.ratings,
      this.ratingCount,
      this.quickDeliveryAvailable});

  Product.fromJson(Map<String, dynamic> json) {
    id = _toInt(json['id']);
    title = json['title'];
    slug = json['slug'];
    image = json['image'];
    minimumOrderQuantity = _toInt(json['minimum_order_quantity']);
    quantityStepSize = _toInt(json['quantity_step_size']);
    totalAllowedQuantity = _toInt(json['total_allowed_quantity']);
    shortDescription = json['short_description'];
    estimatedDeliveryTime = json['estimated_delivery_time'].toString();
    imageFit = json['image_fit'];
    storeStatus = json['store_status'] != null
        ? StoreStatus.fromJson(json['store_status'])
        : null;
    ratings = _toDouble(json['ratings']);
    ratingCount = _toInt(json['rating_count']);
    quickDeliveryAvailable = json['quick_delivery_available'] == true ||
        json['quick_delivery_available'] == 1 ||
        json['quick_delivery_available'] == '1';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['slug'] = slug;
    data['image'] = image;
    data['minimum_order_quantity'] = minimumOrderQuantity;
    data['quantity_step_size'] = quantityStepSize;
    data['total_allowed_quantity'] = totalAllowedQuantity;
    data['short_description'] = shortDescription;
    data['estimated_delivery_time'] = estimatedDeliveryTime;
    data['image_fit'] = imageFit;
    if (storeStatus != null) {
      data['store_status'] = storeStatus!.toJson();
    }
    data['ratings'] = ratings;
    data['rating_count'] = ratingCount;
    data['quick_delivery_available'] = quickDeliveryAvailable;
    return data;
  }
}

class StoreStatus {
  bool? isOpen;
  String? status;

  StoreStatus({this.isOpen, this.status});

  StoreStatus.fromJson(Map<String, dynamic> json) {
    isOpen = json['is_open'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['is_open'] = isOpen;
    data['status'] = status;
    return data;
  }
}

class Variant {
  int? id;
  String? sku;
  String? image;
  double? price;
  double? specialPrice;
  double? mrp;
  int? mrpStatus;
  String? pricePerUnit;
  String? measurementUnit;
  int? storeId;
  String? storeSlug;
  String? storeName;
  int? stock;
  List<TieredPricing>? tieredPricing;

  Variant(
      {this.id,
      this.sku,
      this.image,
      this.price,
      this.specialPrice,
      this.mrp,
      this.mrpStatus,
      this.pricePerUnit,
      this.measurementUnit,
      this.storeId,
      this.storeSlug,
      this.storeName,
      this.stock,
      this.tieredPricing});

  Variant.fromJson(Map<String, dynamic> json) {
    id = _toInt(json['id']);
    sku = json['sku'];
    image = json['image'];
    price = _toDouble(json['price']);
    specialPrice = _toDouble(json['special_price']);
    mrp = _toDouble(json['mrp']);
    mrpStatus = _toInt(json['mrp_status']);
    pricePerUnit = json['price_per_unit']?.toString() ?? '';
    measurementUnit = json['measurement_unit']?.toString();
    storeId = _toInt(json['store_id']);
    storeSlug = json['store_slug'];
    storeName = json['store_name'];
    stock = _toInt(json['stock']);
    final dynamic tieredData = json['tiered_pricing'] ??
        json['tieredPricing'] ??
        json['tiered_prices'] ??
        json['bulk_pricing'];
    if (tieredData != null && tieredData is List) {
      tieredPricing = <TieredPricing>[];
      for (var v in tieredData) {
        if (v is Map<String, dynamic>) {
          tieredPricing!.add(TieredPricing.fromJson(v));
        }
      }
      tieredPricing!.sort((a, b) => a.minQty.compareTo(b.minQty));
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['sku'] = sku;
    data['image'] = image;
    data['price'] = price;
    data['special_price'] = specialPrice;
    data['mrp'] = mrp;
    data['mrp_status'] = mrpStatus;
    data['price_per_unit'] = pricePerUnit;
    data['measurement_unit'] = measurementUnit;
    data['store_id'] = storeId;
    data['store_slug'] = storeSlug;
    data['store_name'] = storeName;
    data['stock'] = stock;
    if (tieredPricing != null) {
      data['tiered_pricing'] = tieredPricing!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Store {
  int? id;
  String? name;
  String? slug;

  Store({this.id, this.name, this.slug});

  Store.fromJson(Map<String, dynamic> json) {
    id = _toInt(json['id']);
    name = json['name'];
    slug = json['slug'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    return data;
  }
}
