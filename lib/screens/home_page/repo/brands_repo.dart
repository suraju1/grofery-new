import '../../../config/api_base_helper.dart';
import '../../../config/api_routes.dart';
import '../../../config/constant.dart';
import '../../../services/location/location_service.dart';

class BrandsRepository {

  Future<Map<String, dynamic>> fetchBrands(
      {required String categorySlug,
        required String brandIds
      }) async {
    try{
      final locationService = LocationService.getStoredLocation();
      final latitude = locationService!.latitude;
      final longitude = locationService.longitude;
      String apiUrl = '';
      String brandsParam = '';
      if(brandIds.isNotEmpty){
        brandsParam = '&ids=$brandIds';
      }
      if(categorySlug.isNotEmpty){
        apiUrl = '${ApiRoutes.brandsApi}?scope_category_slug=$categorySlug&latitude=$latitude&longitude=$longitude$brandsParam';
      } else {
        apiUrl = '${ApiRoutes.brandsApi}?latitude=$latitude&longitude=$longitude$brandsParam';
      }
      final response = await AppConstant.apiBaseHelper.getAPICall(
          apiUrl,
          {}
      );
      return response.data;
    }catch(e){
      throw ApiException('Failed to fetch Banners');
    }
  }
}