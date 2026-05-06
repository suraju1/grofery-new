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
    String? indicator,
    double? rating,
  }) async {
    try {
      final location = LocationService.getStoredLocation();
      final latitude = location?.latitude ?? AppConstant.defaultLat;
      final longitude = location?.longitude ?? AppConstant.defaultLng;
      String apiUrl = '';

      String buildListParam(String key, List<String> values) {
        if (values.isEmpty) return '';
        return '&$key=${values.map((v) => Uri.encodeComponent(v)).join(',')}';
      }

      final brandQuery = buildListParam('brands', brandSlugs);
      final categoryQuery = buildListParam(
          'categories',
          (categorySlugs.isEmpty && type == ProductListingType.category)
              ? [identifier]
              : categorySlugs);

      final ratingQuery = rating != null ? '&ratings=${rating.toInt()}' : '';
      final indicatorQuery = indicator != null ? '&indicator=$indicator' : '';

      final String filterQuery =
          '$brandQuery$categoryQuery$ratingQuery$indicatorQuery';

      final String encodedIdentifier = Uri.encodeComponent(identifier);

      final String searchApiUrl =
          '${ApiRoutes.searchApi}?search=$encodedIdentifier&per_page=$perPage&page=$currentPage&latitude=$latitude&longitude=$longitude&sort=${sortType ?? SortType.relevance}$filterQuery';

      final String storeApiUrl =
          '${ApiRoutes.storeProductApi}?store=$storeSlug&per_page=$perPage&page=$currentPage&latitude=$latitude&longitude=$longitude&sort=${sortType ?? SortType.relevance}$filterQuery';

      if (isSearchInStore == true) {
        apiUrl =
            '${ApiRoutes.searchApi}?search=$encodedIdentifier&store=$storeSlug&per_page=$perPage&page=$currentPage&latitude=$latitude&longitude=$longitude&sort=${sortType ?? SortType.relevance}$filterQuery';
      } else {
        apiUrl = switch (type) {
          ProductListingType.category =>
            '${ApiRoutes.categoryProductApi}?category_slug=$encodedIdentifier&scope_category_slug=$encodedIdentifier&per_page=$perPage&page=$currentPage&latitude=$latitude&longitude=$longitude&sort=${sortType ?? SortType.relevance}&include_child_categories=${includeChildCategories ?? '1'}$filterQuery',
          ProductListingType.brand =>
            '${ApiRoutes.categoryProductApi}?brands=$encodedIdentifier&per_page=$perPage&page=$currentPage&latitude=$latitude&longitude=$longitude&sort=${sortType ?? SortType.relevance}$filterQuery',
          ProductListingType.store => storeApiUrl,
          ProductListingType.search => searchApiUrl,
          ProductListingType.featuredSection =>
            '${ApiRoutes.specificFeatureSectionProductApi}$encodedIdentifier?latitude=$latitude&longitude=$longitude&per_page=$perPage&page=$currentPage$filterQuery',
          ProductListingType.recommended =>
            '${ApiRoutes.recommendedProductsApi}?latitude=$latitude&longitude=$longitude&per_page=$perPage&page=$currentPage$filterQuery',
        };
      }

      //  debugPrint('🚀 Final Product Listing API URL: $apiUrl');

      final response = await AppConstant.apiBaseHelper.getAPICall(apiUrl, {});
      log('🚀 FINAL API URL: $apiUrl');
      log('📦 RESPONSE DATA COUNT: ${response.data['data'] != null && response.data['data']['data'] != null ? (response.data['data']['data'] as List).length : '0'}');
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
