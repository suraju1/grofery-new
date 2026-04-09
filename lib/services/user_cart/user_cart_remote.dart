import 'package:flutter/foundation.dart';
import 'package:grofery_user/config/api_routes.dart';
import 'package:grofery_user/config/constant.dart';

class CartRemoteRepository {
  Future<Map<String, dynamic>> addItemToCart({
    required Map<String, dynamic> body,
  }) async {
    debugPrint('[API] ADD → body: $body');

    final response = await AppConstant.apiBaseHelper.postAPICall(
      ApiRoutes.addToCartApi,
      body,
    );

    return response.data;
  }

  Future<void> updateItemQuantity({
    required int cartItemId,
    required Map<String, dynamic> body,
  }) async {
    debugPrint('[API] UPDATE → cartItemId:$cartItemId body: $body');

    await AppConstant.apiBaseHelper.postAPICall(
      ApiRoutes.removeItemFromCartApi + cartItemId.toString(),
      body,
    );
  }

  Future<void> removeItemFromCart({
    required int cartItemId,
  }) async {
    debugPrint('[API] DELETE → cartItemId:$cartItemId');

    await AppConstant.apiBaseHelper.deleteAPICall(
      ApiRoutes.removeItemFromCartApi + cartItemId.toString(),
      {},
    );
  }
}
