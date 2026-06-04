import 'package:flutter/foundation.dart';
import 'package:grofery_user/config/api_routes.dart';
import 'package:grofery_user/config/constant.dart';
import 'package:grofery_user/config/api_base_helper.dart';

class TargetGiftRepository {
  Future<Map<String, dynamic>> fetchTargetGift() async {
    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(ApiRoutes.targetGiftApi, {});
      print('\x1B[35m🎯 TARGET CARD API RESPONSE: ${response.data}\x1B[0m');
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch Target Gift');
    }
  }
}
