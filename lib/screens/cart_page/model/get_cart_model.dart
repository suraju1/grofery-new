import 'package:grofery_user/screens/cart_page/model/promo_code_model.dart';
import 'package:grofery_user/model/tiered_pricing.dart';

class TimeSlot {
  int? id;
  String? name;
  String? from;
  String? to;

  TimeSlot({this.id, this.name, this.from, this.to});

  TimeSlot.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name'];
    from = json['from'];
    to = json['to'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['from'] = from;
    data['to'] = to;
    return data;
  }
}

class GetCartModel {
  bool? success;
  String? message;
  CartData? data;

  GetCartModel({this.success, this.message, this.data});

  GetCartModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null && json['data'] is Map) {
      data = CartData.fromJson(json['data'] as Map<String, dynamic>);
    } else {
      data = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (data.isNotEmpty) {
      data['data'] = this.data?.toJson();
    } else {
      data['data'] = null;
    }
    return data;
  }
}

class CartData {
  int? id;
  String? uuid;
  int? userId;
  int? itemsCount;
  int? totalQuantity;
  List<CartItems>? items;
  PaymentSummary? paymentSummary;
  List<RemovedItems>? removedItems;
  int? removedCount;
  DeliveryZone? deliveryZone;
  List<TimeSlot>? timeSlots;
  String? createdAt;
  String? updatedAt;

  CartData(
      {this.id,
        this.uuid,
        this.userId,
        this.itemsCount,
        this.totalQuantity,
        this.items,
        this.paymentSummary,
        this.deliveryZone,
        this.timeSlots,
        this.createdAt,
        this.updatedAt});

  CartData.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    uuid = json['uuid'];
    userId = json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null;
    itemsCount = json['items_count'] != null ? int.tryParse(json['items_count'].toString()) : null;
    totalQuantity = json['total_quantity'] != null ? int.tryParse(json['total_quantity'].toString()) : null;
    if (json['items'] != null && json['items'] is List) {
      items = <CartItems>[];
      for (var v in json['items'] as List) {
        if (v is Map<String, dynamic>) {
          items!.add(CartItems.fromJson(v));
        }
      }
    }
    paymentSummary = json['payment_summary'] != null && json['payment_summary'] is Map
        ? PaymentSummary.fromJson(json['payment_summary'])
        : null;
    if (json['removed_items'] != null && json['removed_items'] is List) {
      removedItems = <RemovedItems>[];
      for (var v in json['removed_items'] as List) {
        if (v is Map<String, dynamic>) {
          removedItems!.add(RemovedItems.fromJson(v));
        }
      }
    }
    removedCount = json['removed_count'];
    deliveryZone = json['delivery_zone'] != null && json['delivery_zone'] is Map
        ? DeliveryZone.fromJson(json['delivery_zone'])
        : null;
    final dynamic rawCartTimeSlots = json['time_slots'];
    if (rawCartTimeSlots != null) {
      timeSlots = <TimeSlot>[];
      if (rawCartTimeSlots is Map<String, dynamic>) {
        if (rawCartTimeSlots['normal'] is List) {
          for (var v in rawCartTimeSlots['normal'] as List) {
            if (v is Map<String, dynamic>) timeSlots!.add(TimeSlot.fromJson(v));
          }
        }
        if (rawCartTimeSlots['quick'] is List) {
          for (var v in rawCartTimeSlots['quick'] as List) {
            if (v is Map<String, dynamic>) timeSlots!.add(TimeSlot.fromJson(v));
          }
        }
      } else if (rawCartTimeSlots is List) {
        for (var v in rawCartTimeSlots) {
          if (v is Map<String, dynamic>) timeSlots!.add(TimeSlot.fromJson(v));
        }
      }
    }
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uuid'] = uuid;
    data['user_id'] = userId;
    data['items_count'] = itemsCount;
    data['total_quantity'] = totalQuantity;
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    if (paymentSummary != null) {
      data['payment_summary'] = paymentSummary!.toJson();
    }
    if (removedItems != null) {
      data['removed_items'] =
          removedItems!.map((v) => v.toJson()).toList();
    }
    data['removed_count'] = removedCount;
    if (deliveryZone != null) {
      data['delivery_zone'] = deliveryZone!.toJson();
    }
    if (timeSlots != null) {
      data['time_slots'] = timeSlots!.map((v) => v.toJson()).toList();
    }
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class CartItems {
  int? id;
  int? cartId;
  int? productId;
  int? productVariantId;
  int? storeId;
  int? quantity;
  bool? saveForLater;
  String? tierPrice;
  Product? product;
  Variant? variant;
  Store? store;
  String? createdAt;
  String? updatedAt;

  CartItems(
      {this.id,
        this.cartId,
        this.productId,
        this.productVariantId,
        this.storeId,
        this.quantity,
        this.saveForLater,
        this.tierPrice,
        this.product,
        this.variant,
        this.store,
        this.createdAt,
        this.updatedAt});

  CartItems.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    cartId = json['cart_id'] != null ? int.tryParse(json['cart_id'].toString()) : null;
    productId = json['product_id'] != null ? int.tryParse(json['product_id'].toString()) : null;
    productVariantId = json['product_variant_id'] != null ? int.tryParse(json['product_variant_id'].toString()) : null;
    storeId = json['store_id'] != null ? int.tryParse(json['store_id'].toString()) : null;
    quantity = json['quantity'] != null ? int.tryParse(json['quantity'].toString()) : null;
    saveForLater = json['save_for_later'] != null ? (json['save_for_later'].toString() == 'true' || json['save_for_later'].toString() == '1') : null;
    tierPrice = json['tier_price']?.toString();
    product =
    (json['product'] != null && json['product'] is Map) ? Product.fromJson(json['product']) : null;
    variant =
    (json['variant'] != null && json['variant'] is Map) ? Variant.fromJson(json['variant']) : null;
    store = (json['store'] != null && json['store'] is Map) ? Store.fromJson(json['store']) : null;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['cart_id'] = cartId;
    data['product_id'] = productId;
    data['product_variant_id'] = productVariantId;
    data['store_id'] = storeId;
    data['quantity'] = quantity;
    data['save_for_later'] = saveForLater;
    data['tier_price'] = tierPrice;
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
  String? name;
  String? slug;
  int? minimumOrderQuantity;
  int? quantityStepSize;
  int? totalAllowedQuantity;
  bool? isAttachmentRequired;
  String? image;
  int? estimatedDeliveryTime;
  String? imageFit;
  StoreStatus? storeStatus;
  int? ratings;
  int? ratingCount;

  Product(
      {this.id,
        this.name,
        this.slug,
        this.minimumOrderQuantity,
        this.quantityStepSize,
        this.totalAllowedQuantity,
        this.isAttachmentRequired,
        this.image,
        this.estimatedDeliveryTime,
        this.imageFit,
        this.storeStatus,
        this.ratings,
        this.ratingCount});

  Product.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name'];
    slug = json['slug'];
    minimumOrderQuantity = json['minimum_order_quantity'] != null ? int.tryParse(json['minimum_order_quantity'].toString()) : null;
    quantityStepSize = json['quantity_step_size'] != null ? int.tryParse(json['quantity_step_size'].toString()) : null;
    totalAllowedQuantity = json['total_allowed_quantity'] != null ? int.tryParse(json['total_allowed_quantity'].toString()) : null;
    isAttachmentRequired = json['is_attachment_required'] != null ? (json['is_attachment_required'].toString() == 'true' || json['is_attachment_required'].toString() == '1') : null;
    image = json['image'];
    estimatedDeliveryTime = json['estimated_delivery_time'] != null ? int.tryParse(json['estimated_delivery_time'].toString()) : null;
    imageFit = json['image_fit'];
    storeStatus = (json['store_status'] != null && json['store_status'] is Map)
        ? StoreStatus.fromJson(json['store_status'])
        : null;
    ratings = json['ratings'] != null ? int.tryParse(json['ratings'].toString()) : null;
    ratingCount = json['rating_count'] != null ? int.tryParse(json['rating_count'].toString()) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    data['minimum_order_quantity'] = minimumOrderQuantity;
    data['quantity_step_size'] = quantityStepSize;
    data['total_allowed_quantity'] = totalAllowedQuantity;
    data['is_attachment_required'] = isAttachmentRequired;
    data['image'] = image;
    data['estimated_delivery_time'] = estimatedDeliveryTime;
    data['image_fit'] = imageFit;
    if (storeStatus != null) {
      data['store_status'] = storeStatus!.toJson();
    }
    data['ratings'] = ratings;
    data['rating_count'] = ratingCount;
    return data;
  }
}

class Variant {
  int? id;
  String? title;
  String? slug;
  String? image;
  num? price;
  num? specialPrice;
  int? stock;
  String? sku;
  List<TieredPricing>? tieredPricing;

  Variant({
    this.id,
    this.title,
    this.slug,
    this.image,
    this.price,
    this.specialPrice,
    this.stock,
    this.sku,
    this.tieredPricing,
  });

  Variant.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    title = json['title'];
    slug = json['slug'];
    image = json['image'];
    
    // Safely parse price and specialPrice in case backend sends string
    price = json['price'] != null ? num.tryParse(json['price'].toString()) : null;
    specialPrice = json['special_price'] != null ? num.tryParse(json['special_price'].toString()) : null;
    
    stock = json['stock'] != null ? int.tryParse(json['stock'].toString()) : null;
    sku = json['sku'];

    final dynamic tieredData = json['tiered_pricing'] ?? json['tieredPricing'] ?? json['tiered_prices'] ?? json['bulk_pricing'];
    if (tieredData != null) {
      tieredPricing = <TieredPricing>[];
      if (tieredData is List) {
        for (var v in tieredData) {
          tieredPricing!.add(TieredPricing.fromJson(v));
        }
        tieredPricing!.sort((a, b) => a.minQty.compareTo(b.minQty));
      }
    } else {
      tieredPricing = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['slug'] = slug;
    data['image'] = image;
    data['price'] = price;
    data['special_price'] = specialPrice;
    data['stock'] = stock;
    data['sku'] = sku;
    if (tieredPricing != null) {
      data['tiered_pricing'] = tieredPricing!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class StoreStatus {
  bool? isOpen;
  String? status;

  StoreStatus({this.isOpen, this.status});

  StoreStatus.fromJson(Map<String, dynamic> json) {
    isOpen = json['is_open'] != null ? (json['is_open'].toString() == 'true' || json['is_open'].toString() == '1') : null;
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['is_open'] = isOpen;
    data['status'] = status;
    return data;
  }
}

class Store {
  int? id;
  String? name;
  String? slug;
  int? totalProducts;
  Status? status;

  Store({
    this.id,
    this.name,
    this.slug,
    this.totalProducts,
    this.status
  });

  Store.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name'];
    slug = json['slug'];
    totalProducts = json['total_products'] != null ? int.tryParse(json['total_products'].toString()) : null;
    status = (json['status'] != null && json['status'] is Map) ? Status.fromJson(json['status']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    data['total_products'] = totalProducts;
    if (status != null) {
      data['status'] = status!.toJson();
    }
    return data;
  }
}

class Status {
  bool? isOpen;
  String? status;

  Status({this.isOpen, this.status});

  Status.fromJson(Map<String, dynamic> json) {
    isOpen = json['is_open'] != null ? (json['is_open'].toString() == 'true' || json['is_open'].toString() == '1') : null;
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['is_open'] = isOpen;
    data['status'] = status;
    return data;
  }
}

class PaymentSummary {
  double? itemsTotal;
  double? perStoreDropOffFee;
  bool? isRushDelivery;
  bool? isRushDeliveryAvailable;
  double? deliveryCharges;
  double? handlingCharges;
  double? deliveryDistanceCharges;
  double? deliveryDistanceKm;
  int? totalStores;
  double? totalDeliveryCharges;
  int? estimatedDeliveryTime;
  bool? useWallet;
  String? promoCode;
  String? promoDiscount;
  PromoCodeData? promoApplied;
  String? promoError;
  double? walletBalance;
  double? walletAmountUsed;
  double? payableAmount;

  PaymentSummary(
      {this.itemsTotal,
        this.perStoreDropOffFee,
        this.isRushDelivery,
        this.isRushDeliveryAvailable,
        this.deliveryCharges,
        this.handlingCharges,
        this.deliveryDistanceCharges,
        this.deliveryDistanceKm,
        this.totalStores,
        this.totalDeliveryCharges,
        this.estimatedDeliveryTime,
        this.useWallet,
        this.promoCode,
        this.promoDiscount,
        this.promoApplied,
        this.promoError,
        this.walletBalance,
        this.walletAmountUsed,
        this.payableAmount});

  PaymentSummary.fromJson(Map<String, dynamic> json) {
    itemsTotal = json['items_total'] != null ? double.tryParse(json['items_total'].toString()) : null;
    perStoreDropOffFee = json['per_store_drop_off_fee'] != null ? double.tryParse(json['per_store_drop_off_fee'].toString()) : null;
    isRushDelivery = json['is_rush_delivery'] != null ? (json['is_rush_delivery'].toString() == 'true' || json['is_rush_delivery'].toString() == '1') : null;
    isRushDeliveryAvailable = json['is_rush_delivery_available'] != null ? (json['is_rush_delivery_available'].toString() == 'true' || json['is_rush_delivery_available'].toString() == '1') : null;
    deliveryCharges = json['delivery_charges'] != null ? double.tryParse(json['delivery_charges'].toString()) : null;
    handlingCharges = json['handling_charges'] != null ? double.tryParse(json['handling_charges'].toString()) : null;
    deliveryDistanceCharges = json['delivery_distance_charges'] != null ? double.tryParse(json['delivery_distance_charges'].toString()) : null;
    deliveryDistanceKm = json['delivery_distance_km'] != null ? double.tryParse(json['delivery_distance_km'].toString()) : null;
    totalStores = json['total_stores'] != null ? int.tryParse(json['total_stores'].toString()) : null;
    totalDeliveryCharges = json['total_delivery_charges'] != null ? double.tryParse(json['total_delivery_charges'].toString()) : null;
    estimatedDeliveryTime = json['estimated_delivery_time'] != null ? int.tryParse(json['estimated_delivery_time'].toString()) : null;
    useWallet = json['use_wallet'] != null ? (json['use_wallet'].toString() == 'true' || json['use_wallet'].toString() == '1') : null;
    promoCode = json['promo_code'];
    promoDiscount = json['promo_discount']?.toString();
    final promoData = json['promo_applied'];
    if (promoData is Map<String, dynamic>) {
      promoApplied = PromoCodeData.fromJson(promoData);
    } else if (promoData is List && promoData.isNotEmpty) {
      promoApplied = PromoCodeData.fromJson(promoData.first);
    } else {
      promoApplied = null;
    }
    promoError = json['promo_error'];
    walletBalance = json['wallet_balance'] != null ? double.tryParse(json['wallet_balance'].toString()) : null;
    walletAmountUsed = json['wallet_amount_used'] != null ? double.tryParse(json['wallet_amount_used'].toString()) : 0.0;
    payableAmount = json['payable_amount'] != null ? double.tryParse(json['payable_amount'].toString()) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['items_total'] = itemsTotal;
    data['per_store_drop_off_fee'] = perStoreDropOffFee;
    data['is_rush_delivery'] = isRushDelivery;
    data['is_rush_delivery_available'] = isRushDeliveryAvailable;
    data['delivery_charges'] = deliveryCharges;
    data['handling_charges'] = handlingCharges;
    data['delivery_distance_charges'] = deliveryDistanceCharges;
    data['delivery_distance_km'] = deliveryDistanceKm;
    data['total_stores'] = totalStores;
    data['total_delivery_charges'] = totalDeliveryCharges;
    data['estimated_delivery_time'] = estimatedDeliveryTime;
    data['use_wallet'] = useWallet;
    data['promo_code'] = promoCode;
    data['promo_discount'] = promoDiscount;
    if (promoApplied != null) {
      data['promo_applied'] = promoApplied!.toJson();
    }
    data['promo_error'] = promoError;
    data['wallet_balance'] = walletBalance;
    data['wallet_amount_used'] = walletAmountUsed;
    data['payable_amount'] = payableAmount;
    return data;
  }
}


class RemovedItems {
  String? productName;
  String? variantName;
  String? storeName;
  int? quantity;
  String? reason;

  RemovedItems(
      {this.productName,
        this.variantName,
        this.storeName,
        this.quantity,
        this.reason});

  RemovedItems.fromJson(Map<String, dynamic> json) {
    productName = json['product_name'];
    variantName = json['variant_name'];
    storeName = json['store_name'];
    quantity = json['quantity'];
    reason = json['reason'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product_name'] = productName;
    data['variant_name'] = variantName;
    data['store_name'] = storeName;
    data['quantity'] = quantity;
    data['reason'] = reason;
    return data;
  }
}

class DeliveryZone {
  bool? exists;
  String? zone;
  int? zoneCount;
  int? zoneId;
  int? handlingCharges;
  int? deliveryTimePerKm;
  bool? rushDeliveryEnabled;
  int? rushDeliveryTimePerKm;
  int? rushDeliveryCharges;
  int? regularDeliveryCharges;
  int? freeDeliveryAmount;
  int? distanceBasedDeliveryCharges;
  int? perStoreDropOffFee;
  int? bufferTime;
  bool? rushDeliveryAvailable;
  List<TimeSlot>? timeSlots;

  DeliveryZone(
      {this.exists,
        this.zone,
        this.zoneCount,
        this.zoneId,
        this.handlingCharges,
        this.deliveryTimePerKm,
        this.rushDeliveryEnabled,
        this.rushDeliveryTimePerKm,
        this.rushDeliveryCharges,
        this.regularDeliveryCharges,
        this.freeDeliveryAmount,
        this.distanceBasedDeliveryCharges,
        this.perStoreDropOffFee,
        this.bufferTime,
        this.rushDeliveryAvailable,
        this.timeSlots});

  DeliveryZone.fromJson(Map<String, dynamic> json) {
    exists = json['exists'] != null ? (json['exists'].toString() == 'true' || json['exists'].toString() == '1') : null;
    zone = json['zone'];
    zoneCount = json['zone_count'] != null ? int.tryParse(json['zone_count'].toString()) : null;
    zoneId = json['zone_id'] != null ? int.tryParse(json['zone_id'].toString()) : null;
    handlingCharges = json['handling_charges'] != null ? int.tryParse(json['handling_charges'].toString()) : null;
    deliveryTimePerKm = json['delivery_time_per_km'] != null ? int.tryParse(json['delivery_time_per_km'].toString()) : null;
    rushDeliveryEnabled = json['rush_delivery_enabled'] != null ? (json['rush_delivery_enabled'].toString() == 'true' || json['rush_delivery_enabled'].toString() == '1') : null;
    rushDeliveryTimePerKm = json['rush_delivery_time_per_km'] != null ? int.tryParse(json['rush_delivery_time_per_km'].toString()) : null;
    rushDeliveryCharges = json['rush_delivery_charges'] != null ? int.tryParse(json['rush_delivery_charges'].toString()) : null;
    regularDeliveryCharges = json['regular_delivery_charges'] != null ? int.tryParse(json['regular_delivery_charges'].toString()) : null;
    freeDeliveryAmount = json['free_delivery_amount'] != null ? int.tryParse(json['free_delivery_amount'].toString()) : null;
    distanceBasedDeliveryCharges = json['distance_based_delivery_charges'] != null ? int.tryParse(json['distance_based_delivery_charges'].toString()) : null;
    perStoreDropOffFee = json['per_store_drop_off_fee'] != null ? int.tryParse(json['per_store_drop_off_fee'].toString()) : null;
    bufferTime = json['buffer_time'] != null ? int.tryParse(json['buffer_time'].toString()) : null;
    rushDeliveryAvailable = json['rush_delivery_available'] != null ? (json['rush_delivery_available'].toString() == 'true' || json['rush_delivery_available'].toString() == '1') : null;
    final dynamic rawSlots = json['time_slots'];
    if (rawSlots != null) {
      timeSlots = <TimeSlot>[];
      if (rawSlots is Map<String, dynamic>) {
        if (rawSlots['normal'] is List) {
          for (var v in rawSlots['normal'] as List) {
            if (v is Map<String, dynamic>) timeSlots!.add(TimeSlot.fromJson(v));
          }
        }
        if (rawSlots['quick'] is List) {
          for (var v in rawSlots['quick'] as List) {
            if (v is Map<String, dynamic>) timeSlots!.add(TimeSlot.fromJson(v));
          }
        }
      } else if (rawSlots is List) {
        for (var v in rawSlots) {
          if (v is Map<String, dynamic>) timeSlots!.add(TimeSlot.fromJson(v));
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['exists'] = exists;
    data['zone'] = zone;
    data['zone_count'] = zoneCount;
    data['zone_id'] = zoneId;
    data['handling_charges'] = handlingCharges;
    data['delivery_time_per_km'] = deliveryTimePerKm;
    data['rush_delivery_enabled'] = rushDeliveryEnabled;
    data['rush_delivery_time_per_km'] = rushDeliveryTimePerKm;
    data['rush_delivery_charges'] = rushDeliveryCharges;
    data['regular_delivery_charges'] = regularDeliveryCharges;
    data['free_delivery_amount'] = freeDeliveryAmount;
    data['distance_based_delivery_charges'] = distanceBasedDeliveryCharges;
    data['per_store_drop_off_fee'] = perStoreDropOffFee;
    data['buffer_time'] = bufferTime;
    data['rush_delivery_available'] = rushDeliveryAvailable;
    if (timeSlots != null) {
      data['time_slots'] = timeSlots!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
