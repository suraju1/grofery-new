
import 'package:flutter/foundation.dart';
import 'package:grofery_user/config/api_base_helper.dart';
import 'package:grofery_user/config/api_routes.dart';
import 'package:grofery_user/config/constant.dart';

class AddressRepository {

  Future<Map<String, dynamic>> addAddressRequest({
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String landmark,
    required String state,
    required String zipcode,
    required String mobile,
    required String addressType,
    required String country,
    required String countryCode,
    required String latitude,
    required String longitude,
  }) async {
    try {
      debugPrint('📍 API Request for Add Address: ${ApiRoutes.addAddressApi}');
      debugPrint('📍 Payload: ${AppConstant.isDemo ? AppConstant.defaultFullAddress : {
        "address_line1": addressLine1,
        "address_line2": addressLine2,
        "city": city,
        "landmark": landmark,
        "state": state,
        "zipcode": zipcode,
        "mobile": mobile,
        "address_type": addressType.toLowerCase(),
        "country": country,
        "country_code": countryCode,
        "latitude": latitude,
        "longitude": longitude
      }}');

      final response = await AppConstant.apiBaseHelper.postAPICall(
        ApiRoutes.addAddressApi,
        AppConstant.isDemo ? AppConstant.defaultFullAddress
            : {
          "address_line1": addressLine1,
          "address_line2": addressLine2,
          "city": city,
          "landmark": landmark,
          "state": state,
          "zipcode": zipcode,
          "mobile": mobile,
          "address_type": addressType.toLowerCase(),
          "country": country,
          "country_code": countryCode,
          "latitude": latitude,
          "longitude": longitude
        }
      );

      debugPrint('📍 API Response Status: ${response.statusCode}');
      debugPrint('📍 API Response Data: ${response.data}');

      if(response.statusCode == 200 || response.statusCode == 201) {
        if(response.data['success'] == true && response.data['data'] != null) {
          return response.data;
        } else {
          throw ApiException(response.data['message'] ?? 'Failed to add address (success = false)');
        }
      } else {
        throw ApiException('Failed to add address (status code: ${response.statusCode})');
      }
    } catch(e, stack) {
      debugPrint('❌ addAddressRequest Error: $e');
      debugPrint('❌ addAddressRequest Stack: $stack');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchAddressList({int? deliveryZoneId}) async {
    try{
      String apiUrl = '';
      if(deliveryZoneId != null) {
        apiUrl = '${ApiRoutes.getAddressesApi}?zone_id=$deliveryZoneId';
      } else {
        apiUrl = ApiRoutes.getAddressesApi;
      }
      debugPrint("DEBUG_API: [AddressRepository.fetchAddressList] Requesting API: $apiUrl");
      final response = await AppConstant.apiBaseHelper.getAPICall(
        apiUrl,
        {},
      );
      if(response.statusCode == 200 || response.data['success'] == true) {
        return response.data;
      } else {
        return {};
      }
    }catch(e){
      throw ApiException('Failed to get address list');
    }
  }

  Future<Map<String, dynamic>> removeAddress ({required int addressId}) async {
    try{
      final response = await AppConstant.apiBaseHelper.deleteAPICall(
          '${ApiRoutes.removeAddressesApi}${addressId.toString()}',
          {}
      );
      if(response.statusCode == 200) {
        return response.data;
      } else {
        return {};
      }
    }catch(e){
      throw ApiException('Failed to remove item from cart');
    }
  }

  Future<Map<String, dynamic>> updateAddress ({
    required int addressId,
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String landmark,
    required String state,
    required String zipcode,
    required String mobile,
    required String addressType,
    required String country,
    required String countryCode,
    required String latitude,
    required String longitude,
  }) async {
    try{
      final response = await AppConstant.apiBaseHelper.putAPICall(
          '${ApiRoutes.updateAddressesApi}${addressId.toString()}',
          AppConstant.isDemo ? AppConstant.defaultFullAddress
              : {
            'address_line1': addressLine1,
            'address_line2': addressLine2,
            'city': city,
            'landmark': landmark,
            'state': state,
            'zipcode': zipcode,
            'mobile': mobile,
            'address_type': addressType.toLowerCase(),
            'country': country,
            'country_code': countryCode,
            'latitude': latitude,
            'longitude': longitude
          }
      );
      if(response.statusCode == 200) {
        return response.data;
      } else {
        return {};
      }
    }catch(e){
      throw ApiException('Failed to remove item from cart');
    }
  }
}

