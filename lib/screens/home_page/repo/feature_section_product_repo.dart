import 'dart:developer';
import 'package:grofery_user/config/api_base_helper.dart';
import 'package:grofery_user/config/api_routes.dart';
import 'package:grofery_user/config/constant.dart';
import 'package:grofery_user/services/location/location_service.dart';

class FeatureSectionProductRepository {

  Future<Map<String, dynamic>> fetchFeatureSectionProduct({
    required String slug,
    required int perPage,
    required int page,
  }) async {
    try{
      final locationService = LocationService.getStoredLocation();
      if (locationService == null) {
        return {'success': false, 'message': 'Location not found', 'data': {'data': []}};
      }
      final latitude = locationService.latitude;
      final longitude = locationService.longitude;
      String apiUrl = '';
      if(slug.isNotEmpty){
        apiUrl = '${ApiRoutes.featureSectionProductApi}?scope_category_slug=$slug&latitude=$latitude&longitude=$longitude&page=$page&per_page=$perPage';
      } else {
        apiUrl = '${ApiRoutes.featureSectionProductApi}?latitude=$latitude&longitude=$longitude&page=$page&per_page=$perPage';
      }
      final response = await AppConstant.apiBaseHelper.getAPICall(
        apiUrl,
        {}
      );
      log('🏷️ Feature Section Product API: $apiUrl');
      log('📦 Response: ${response.data}');
      return response.data;
    }catch(e){
      throw ApiException(e.toString());
    }
  }
}