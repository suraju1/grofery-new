import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grofery_user/config/api_base_helper.dart';
import 'package:grofery_user/config/api_routes.dart';
import 'package:grofery_user/config/constant.dart';
import 'package:grofery_user/services/location/location_service.dart';
import '../model/get_cart_model.dart';

class CartRepository {
  Future<dynamic> addItemToCart({
    required int productVariantId,
    required int storeId,
    required int quantity,
  }) async {
    try {
      final response = await AppConstant.apiBaseHelper.postAPICall(
        ApiRoutes.addToCartApi,
        {
          'product_variant_id': productVariantId,
          'store_id': storeId,
          'quantity': quantity,
        },
      );
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> updateItemQuantity({
    required int cartItemId,
    required int quantity,
  }) async {
    try {
      // FIX: Was using removeItemFromCartApi (DELETE route) — which caused the
      // server to delete the item instead of updating it. Now using the correct
      // updateCartItemApi (POST/PUT route) for quantity updates.
      final response = await AppConstant.apiBaseHelper.postAPICall(
        ApiRoutes.updateCartItemApi + cartItemId.toString(),
        {
          'quantity': quantity,
        },
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        debugPrint('❌ updateItemQuantity failed: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      throw ApiException(
          'Failed to update cart item quantity: ${e.toString()}');
    }
  }

  Future<List<GetCartModel>> getCartItems({
    required int? addressId,
    String? promoCode,
    bool? rushDelivery,
    bool? useWallet,
  }) async {
    try {
      final location = LocationService.getStoredLocation();
      final queryParams = <String, String>{};
      if (addressId != null) queryParams['address_id'] = addressId.toString();
      if (promoCode != null && promoCode.isNotEmpty)
        queryParams['promo_code'] = promoCode;
      if (rushDelivery != null)
        queryParams['rush_delivery'] = rushDelivery.toString();
      if (useWallet != null) queryParams['use_wallet'] = useWallet.toString();
      queryParams['latitude'] = location!.latitude.toString();
      queryParams['longitude'] = location.longitude.toString();

      final uri =
          Uri.parse(ApiRoutes.getCartApi).replace(queryParameters: queryParams);

      // final uri = Uri.parse(ApiRoutes.getCartApi);

      debugPrint(
          "DEBUG_API: [CartRepository.getCartItems] Requesting API: ${uri.toString()}");

      final response = await AppConstant.apiBaseHelper.getAPICall(
        uri.toString(),
        {},
      );

      debugPrint('🛒 GET CART API URL: ${uri.toString()}');
      try {
        debugPrint('🛒 GET CART API RESPONSE: ${jsonEncode(response.data)}');
      } catch (e) {
        debugPrint('🛒 GET CART API RESPONSE (Raw): ${response.data}');
      }

      dynamic responseData;
      if (response.statusCode == 200) {
        responseData = response.data;
        final List<GetCartModel> getCart = [];
        getCart.add(GetCartModel.fromJson(responseData));
        return getCart;
      } else {
        return [];
      }
    } catch (e, stacktrace) {
      debugPrint('❌ GET CART FORMAT ERROR: $e');
      debugPrint('❌ GET CART STACKTRACE: $stacktrace');
      throw ApiException('Failed to get cart items: $e');
    }
  }

  Future<Map<String, dynamic>> removeItemFromCart(
      {required int cartItemId}) async {
    try {
      final response = await AppConstant.apiBaseHelper.deleteAPICall(
        ApiRoutes.removeItemFromCartApi + cartItemId.toString(),
        {},
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        debugPrint('❌ removeItemFromCart failed: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      throw ApiException('Failed to remove item from cart: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> clearCart() async {
    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.clearCartApi,
        {},
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        debugPrint('❌ clearCart failed: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      throw ApiException('Failed to clear cart: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> syncCart({
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final payload = {'items': items};

      debugPrint('[SYNC] Sending cart sync payload: ${jsonEncode(payload)}');

      final response = await AppConstant.apiBaseHelper.postAPICall(
        ApiRoutes.cartSyncApi,
        payload,
      );

      debugPrint('[SYNC] Response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw ApiException('Failed to sync cart: ${response.data.toString()}');
      }
    } catch (e) {
      debugPrint('[SYNC] Error: $e');
      throw ApiException('Failed to sync cart: $e');
    }
  }
}
