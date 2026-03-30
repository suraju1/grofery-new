import 'dart:developer';
import 'package:grofery_user/config/api_base_helper.dart';
import 'package:grofery_user/config/api_routes.dart';
import 'package:grofery_user/services/location/location_service.dart';

class ProductDetailRepository {
  final ApiBaseHelper apiBaseHelper = ApiBaseHelper();

  Future<Map<String, dynamic>> fetchProductDetail({required String productSlug}) async {
    try{
      final locationService = LocationService.getStoredLocation();
      final latitude = locationService!.latitude;
      final longitude = locationService.longitude;
      final url = '${ApiRoutes.productDetailApi}$productSlug?latitude=$latitude&longitude=$longitude';
      final response = await apiBaseHelper.getAPICall(url, {});
      log('🛒 Product Detail API: $url');
      log('📦 Response: ${response.data}');
      return response.data;
    }catch(e){
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchSimilarProduct({required List<String> excludeProductSlug}) async {
    try{
      final locationService = LocationService.getStoredLocation();
      final latitude = locationService!.latitude;
      final longitude = locationService.longitude;

      String apiUrl = '';
      if(excludeProductSlug.isNotEmpty){
        String excludeParam = excludeProductSlug.join(",");
        apiUrl = '${ApiRoutes.getSimilarProductApi}?exclude_product=$excludeParam&latitude=$latitude&longitude=$longitude';
      } else {
        apiUrl = '${ApiRoutes.getSimilarProductApi}?latitude=$latitude&longitude=$longitude';
      }
      final response = await apiBaseHelper.getAPICall(apiUrl, {});
      log('🔁 Similar Products API: $apiUrl');
      log('📦 Response: ${response.data}');
      return response.data;
    } catch(e){
      throw ApiException('Failed to fetch similar product');
    }
  }
}