import 'package:flutter/foundation.dart';
import 'package:grofery_user/config/api_base_helper.dart';
import 'package:grofery_user/config/api_routes.dart';

import '../../../config/constant.dart';
import '../../../services/location/location_service.dart';

class CategoryRepository {
  Future<Map<String, dynamic>> fetchCategory(
      {required int perPage,
      required int currentPage,
      String? categoryIds}) async {
    try {
      final locationService = LocationService.getStoredLocation();
      if (locationService == null) {
        return {'success': false, 'message': 'Location not found', 'data': {'data': []}};
      }
      final latitude = locationService.latitude;
      final longitude = locationService.longitude;
      String categoryParam = '';
      if (categoryIds != null && categoryIds.isNotEmpty) {
        categoryParam = '&ids=$categoryIds';
      }
      final response = await AppConstant.apiBaseHelper.getAPICall(
          '${ApiRoutes.categoryApi}?per_page=$perPage&page=$currentPage&latitude=$latitude&longitude=$longitude$categoryParam',
          {});
      // log('Category Response: ${response.data}');
      debugPrint('Category Response: ${response.data}');
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch categories');
    }
  }
}
