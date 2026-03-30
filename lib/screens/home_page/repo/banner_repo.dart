import 'package:flutter/foundation.dart';
import 'package:grofery_user/config/api_routes.dart';
import 'package:grofery_user/config/constant.dart';

import 'package:grofery_user/config/api_base_helper.dart';

import 'package:grofery_user/services/location/location_service.dart';

class BannerRepository {
  Future<Map<String, dynamic>> fetchBanners(
      {required String categorySlug}) async {
    try {
      final locationService = LocationService.getStoredLocation();
      if (locationService == null) {
        return {'success': false, 'message': 'Location not found', 'data': {'data': {'top': [], 'carousel': []}}};
      }
      final latitude = locationService.latitude;
      final longitude = locationService.longitude;
      String apiUrl = '';
      if (categorySlug.isNotEmpty) {
        apiUrl =
            '${ApiRoutes.bannerApi}?scope_category_slug=$categorySlug&latitude=$latitude&longitude=$longitude';
      } else {
        apiUrl =
            '${ApiRoutes.bannerApi}?latitude=$latitude&longitude=$longitude';
      }
      final response = await AppConstant.apiBaseHelper.getAPICall(apiUrl, {});
      debugPrint("Banner Response: ${response.data}");
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch Banners');
    }
  }
}
