import 'package:grofery_user/screens/home_page/model/banner_model.dart';

class AuthModel {
  bool? success;
  String? message;
  String? accessToken;
  String? tokenType;
  Data? data;

  AuthModel(
      {this.success,
      this.message,
      this.accessToken,
      this.tokenType,
      this.data});

  AuthModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    accessToken = json['access_token'];
    tokenType = json['token_type'];

    // Handle both Flat data (Login) and Nested user data (Register)
    if (json['data'] != null) {
      if (json['data']['user'] != null) {
        data = Data.fromJson(json['data']['user']);
      } else {
        data = Data.fromJson(json['data']);
      }
    } else {
      data = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    data['access_token'] = accessToken;
    data['token_type'] = tokenType;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  int? id;
  String? name;
  String? email;
  String? mobile;
  String? country;
  String? iso2;
  int? walletBalance;
  String? referralCode;
  String? friendsCode;
  int? rewardPoints;
  String? profileImage;
  String? shopName;
  String? emailVerifiedAt;
  String? createdAt;
  String? updatedAt;

  Data(
      {this.id,
      this.name,
      this.email,
      this.mobile,
      this.country,
      this.iso2,
      this.walletBalance,
      this.referralCode,
      this.friendsCode,
      this.rewardPoints,
      this.profileImage,
      this.shopName,
      this.emailVerifiedAt,
      this.createdAt,
      this.updatedAt});

  Data.fromJson(Map<String, dynamic> json) {
    id = parseInt(json['id']);
    name = parseString(json['name']);
    email = parseString(json['email']);
    mobile = parseString(json['mobile']);
    country = parseString(json['country']);
    iso2 = parseString(json['iso_2']);
    walletBalance = parseInt(json['wallet_balance']);
    referralCode = parseString(json['referral_code']);
    friendsCode = parseString(json['friends_code']);
    rewardPoints = parseInt(json['reward_points']);
    profileImage = parseString(json['profile_image']);
    shopName = parseString(json['shop_name']);
    emailVerifiedAt = parseString(json['email_verified_at']);
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['email'] = email;
    data['mobile'] = mobile;
    data['country'] = country;
    data['iso_2'] = iso2;
    data['wallet_balance'] = walletBalance;
    data['referral_code'] = referralCode;
    data['friends_code'] = friendsCode;
    data['reward_points'] = rewardPoints;
    data['profile_image'] = profileImage;
    data['shop_name'] = shopName;
    data['email_verified_at'] = emailVerifiedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
