import 'dart:convert';
import 'dart:developer';

import 'package:grofery_user/config/api_base_helper.dart';
import 'package:grofery_user/config/api_routes.dart';
import 'package:grofery_user/config/constant.dart';

import '../../../services/location/location_service.dart';
import '../model/store_detail_model.dart';

class NearByStoreRepo {
  Future<Map<String, dynamic>?> getNearByStores({
    int page = 1,
    int perPage = 15,
    required String searchQuery,
  }) async {
    try {
      final locationService = LocationService.getStoredLocation();
      if (locationService == null) {
        return null;
      }

      final latitude = locationService.latitude;
      final longitude = locationService.longitude;

      final Map<String, dynamic> query = {
        'latitude': latitude,
        'longitude': longitude,
        'page': page.toString(),
        'per_page': perPage.toString(),
        if(searchQuery.isNotEmpty)
          'search': searchQuery
      };

      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.nearByStores,
        query,
      );

      // Extract .data and ensure it's a Map
      dynamic data = response.data;

      if (data is String) {
        data = jsonDecode(data);
      }

      if (data is Map<String, dynamic>) {
        log('API SUCCESS: Stores fetched');
        return data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<StoreDetailModel>> fetchStoreDetail({required String storeSlug}) async {
    try{
      final locationService = LocationService.getStoredLocation();
      final latitude = locationService!.latitude;
      final longitude = locationService.longitude;

      final response = await AppConstant.apiBaseHelper.getAPICall(
        '${ApiRoutes.storeDetailApi}$storeSlug?latitude=$latitude&longitude=$longitude',
        {}
      );
      if(response.statusCode == 200) {
        List<StoreDetailModel> storeData = [];
        storeData.add(StoreDetailModel.fromJson(response.data));
        return storeData;
      } else {
        return [];
      }
    }catch(e) {

      throw ApiException(e.toString());
    }
  }
}