import 'dart:convert';

class TargetGiftModel {
  final bool? success;
  final double? totalSpent;
  final EligibleGift? eligibleGift;
  final NextGift? nextGift;

  TargetGiftModel({
    this.success,
    this.totalSpent,
    this.eligibleGift,
    this.nextGift,
  });

  factory TargetGiftModel.fromJson(Map<String, dynamic> json) => TargetGiftModel(
        success: json["success"],
        totalSpent: json["total_spent"]?.toDouble(),
        eligibleGift: json["eligible_gift"] == null
            ? null
            : EligibleGift.fromJson(json["eligible_gift"]),
        nextGift: json["next_gift"] == null
            ? null
            : NextGift.fromJson(json["next_gift"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "total_spent": totalSpent,
        "eligible_gift": eligibleGift?.toJson(),
        "next_gift": nextGift?.toJson(),
      };
}

class EligibleGift {
  final String? giftName;
  final String? giftImage;

  EligibleGift({
    this.giftName,
    this.giftImage,
  });

  factory EligibleGift.fromJson(Map<String, dynamic> json) => EligibleGift(
        giftName: json["gift_name"],
        giftImage: json["gift_image"],
      );

  Map<String, dynamic> toJson() => {
        "gift_name": giftName,
        "gift_image": giftImage,
      };
}

class NextGift {
  final String? giftName;
  final double? targetAmount;
  final double? amountNeeded;
  final String? giftImage;

  NextGift({
    this.giftName,
    this.targetAmount,
    this.amountNeeded,
    this.giftImage,
  });

  factory NextGift.fromJson(Map<String, dynamic> json) => NextGift(
        giftName: json["gift_name"],
        targetAmount: json["target_amount"]?.toDouble(),
        amountNeeded: json["amount_needed"]?.toDouble(),
        giftImage: json["gift_image"],
      );

  Map<String, dynamic> toJson() => {
        "gift_name": giftName,
        "target_amount": targetAmount,
        "amount_needed": amountNeeded,
        "gift_image": giftImage,
      };
}
