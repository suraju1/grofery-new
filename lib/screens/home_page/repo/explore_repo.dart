import 'package:flutter/foundation.dart';
import 'package:grofery_user/config/api_base_helper.dart';
import 'package:grofery_user/config/api_routes.dart';
import 'package:grofery_user/config/constant.dart';

class ExploreRepository {
  Future<Map<String, dynamic>> fetchExplores() async {
    try {
      debugPrint("DEBUG_API: [ExploreRepository.fetchExplores] Requesting API: ${ApiRoutes.exploreApi}");
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.exploreApi,
        {}
      );
      debugPrint('Explore Response: ${response.data}');
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch explores');
    }
  }
}
