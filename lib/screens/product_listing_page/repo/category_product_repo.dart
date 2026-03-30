import 'dart:developer';
import 'package:grofery_user/config/api_base_helper.dart';
import 'package:grofery_user/config/api_routes.dart';
import 'package:grofery_user/config/constant.dart';
import 'package:grofery_user/model/sorting_model/sorting_model.dart';
import '../../../services/location/location_service.dart';
import '../model/product_listing_type.dart';

class CategoryProductRepository {

  Future<Map<String, dynamic>> fetchProductsByType({
    required ProductListingType type,
    required String identifier,
    String? storeSlug,
    String? sortType,
    required int perPage,
    required int currentPage,
    bool? isSearchInStore,
    String? includeChildCategories,
    required List<String> categorySlugs,
    required List<String> brandSlugs,
  }) async {
    try {
      final latitude = LocationService.getStoredLocation()!.latitude;
      final longitude = LocationService.getStoredLocation()!.longitude;
      String apiUrl = '';

      String buildListParam(String key, List<String> values) {
        if (values.isEmpty) return '';
        return '&$key=${values.join(',')}';
      }

      final brandQuery = buildListParam('brands', brandSlugs);
      final categoryQuery = buildListParam('categories', categorySlugs);


      final String searchApiUrl =
          '${ApiRoutes.searchApi}?search=$identifier&per_page=$perPage&page=$currentPage&latitude=$latitude&longitude=$longitude&sort=${sortType ?? SortType.relevance}$brandQuery$categoryQuery';

      final String storeApiUrl =
          '${ApiRoutes.storeProductApi}?store=$storeSlug&per_page=$perPage&page=$currentPage&latitude=$latitude&longitude=$longitude&sort=${sortType ?? SortType.relevance}$brandQuery$categoryQuery';

      if (isSearchInStore == true) {
        apiUrl =
            '${ApiRoutes.searchApi}?search=$identifier&store=$storeSlug&per_page=$perPage&page=$currentPage&latitude=$latitude&longitude=$longitude&sort=${sortType ?? SortType.relevance}';
      } else {
        apiUrl = switch (type) {
          ProductListingType.category =>
          '${ApiRoutes.categoryProductApi}?categories=$identifier&per_page=$perPage&page=$currentPage&latitude=$latitude&longitude=$longitude&sort=${sortType ?? SortType.relevance}&include_child_categories=${includeChildCategories ?? '1'}$brandQuery$categoryQuery',
          ProductListingType.brand =>
          '${ApiRoutes.categoryProductApi}?brands=$identifier&per_page=$perPage&page=$currentPage&latitude=$latitude&longitude=$longitude&sort=${sortType ?? SortType.relevance}$brandQuery$categoryQuery',
          ProductListingType.store =>
          storeApiUrl,
          ProductListingType.search =>
          searchApiUrl,
          ProductListingType.featuredSection =>
          '${ApiRoutes.specificFeatureSectionProductApi}$identifier/products?per_page=$perPage&page=$currentPage&latitude=$latitude&longitude=$longitude&sort=${sortType ?? SortType.relevance}$brandQuery$categoryQuery',
        };
      }

      final response = await AppConstant.apiBaseHelper.getAPICall(apiUrl, {});
      log('📋 Product Listing API: $apiUrl');
      log('📦 Response: ${response.data}');
      return response.data;

    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
