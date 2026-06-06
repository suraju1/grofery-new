class OutletModel {
  int? id;
  int? userId;
  String? shopName;
  String? mobile;
  String? email;
  String? gstNumber;
  String? addressLine1;
  String? addressLine2;
  String? city;
  String? state;
  String? zipcode;
  String? country;
  String? latitude;
  String? longitude;
  bool? isDefault;
  String? createdAt;
  String? updatedAt;

  OutletModel({
    this.id,
    this.userId,
    this.shopName,
    this.mobile,
    this.email,
    this.gstNumber,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.zipcode,
    this.country,
    this.latitude,
    this.longitude,
    this.isDefault,
    this.createdAt,
    this.updatedAt,
  });

  OutletModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    shopName = json['shop_name'];
    mobile = json['mobile'];
    email = json['email'];
    gstNumber = json['gst_number'];
    addressLine1 = json['address_line1'];
    addressLine2 = json['address_line2'];
    city = json['city'];
    state = json['state'];
    zipcode = json['zipcode'];
    country = json['country'];
    latitude = json['latitude']?.toString();
    longitude = json['longitude']?.toString();
    isDefault = json['is_default'] == 1 || json['is_default'] == true;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['shop_name'] = shopName;
    data['mobile'] = mobile;
    data['email'] = email;
    data['gst_number'] = gstNumber;
    data['address_line1'] = addressLine1;
    data['address_line2'] = addressLine2;
    data['city'] = city;
    data['state'] = state;
    data['zipcode'] = zipcode;
    data['country'] = country;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['is_default'] = isDefault;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
