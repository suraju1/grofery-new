class ExploreModel {
  bool? success;
  String? message;
  ExploreApiData? data;

  ExploreModel({this.success, this.message, this.data});

  ExploreModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? ExploreApiData.fromJson(json['data']) : null;
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

class ExploreApiData {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  List<ExploreData>? data;

  ExploreApiData(
      {this.currentPage,
      this.lastPage,
      this.perPage,
      this.total,
      this.data});

  ExploreApiData.fromJson(Map<String, dynamic> json) {
    currentPage = json['current_page'];
    lastPage = json['last_page'];
    perPage = json['per_page'];
    total = json['total'];
    if (json['data'] != null) {
      data = <ExploreData>[];
      json['data'].forEach((v) {
        data!.add(ExploreData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    data['last_page'] = lastPage;
    data['per_page'] = perPage;
    data['total'] = total;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ExploreData {
  int? id;
  String? image;
  String? status;
  String? createdAt;
  int? productId;
  String? productSlug;
  String? type;
  String? title;

  ExploreData({
    this.id,
    this.image,
    this.status,
    this.createdAt,
    this.productId,
    this.productSlug,
    this.type,
    this.title,
  });

  ExploreData.fromJson(Map<String, dynamic> json) {
    id = _parseInt(json['id']);
    image = json['image'];
    status = json['status'];
    createdAt = json['created_at'];
    productId = _parseInt(json['product_id']);
    productSlug = json['product_slug']?.toString();
    type = json['type']?.toString();
    title = json['title']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['image'] = image;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['product_id'] = productId;
    data['product_slug'] = productSlug;
    data['type'] = type;
    data['title'] = title;
    return data;
  }

  int? _parseInt(dynamic value) {
    if (value == null || value == "") return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
