import 'dart:developer';
import 'package:grofery_user/config/api_routes.dart';
import 'package:grofery_user/config/constant.dart';
import 'package:grofery_user/services/location/location_service.dart';
import 'package:grofery_user/config/api_base_helper.dart';

class RecommendedProductsRepository {
  Future<Map<String, dynamic>> fetchRecommendedProducts() async {
    try {
      final locationService = LocationService.getStoredLocation();
      if (locationService == null) {
        return {'success': false, 'message': 'Location not found', 'data': []};
      }
      final latitude = locationService.latitude;
      final longitude = locationService.longitude;
      
      String apiUrl = '${ApiRoutes.recommendedProductsApi}?latitude=$latitude&longitude=$longitude';
      
      final response = await AppConstant.apiBaseHelper.getAPICall(
        apiUrl,
        {},
      );
      
      log('🏷️ Recommended Products API: $apiUrl');
      log('📦 Response: ${response.data}'); // For debugging
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
