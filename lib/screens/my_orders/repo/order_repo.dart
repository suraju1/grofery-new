import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:grofery_user/config/api_base_helper.dart';
import 'package:grofery_user/config/constant.dart';
import 'package:grofery_user/config/security.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart' as dio;
import '../../../config/api_routes.dart';
import '../../cart_page/widgets/cart_product_item.dart';
import '../model/order_detail_model.dart';
import '../model/delivery_tracking_model.dart';

class OrderRepository {
  Future<Map<String, dynamic>> createOrder({
    required String paymentType,
    required String promoCode,
    required String giftCard,
    required int addressId,
    required bool rushDelivery,
    required bool useWallet,
    required String orderNote,
    Map<String, dynamic>? paymentDetails,
    required Map<int, CartItemAttachment?> attachments,
    double? usedAmountValue,
    String? deliveryTimeSlotId,
  }) async {
    try {
      String? paymenttype;
      if (paymentType.isNotEmpty && paymentType != 'wallet') {
        paymenttype =
            paymentType == 'cod' ? paymentType : '${paymentType}Payment';
      } else if (paymentType == 'wallet') {
        paymenttype = paymentType;
      } else {
        paymenttype = '';
      }

      final Map<String, dynamic> requestBody = {};
      if (paymenttype != null && paymenttype.isNotEmpty) {
        requestBody['payment_type'] = paymenttype;
      }
      if (promoCode.isNotEmpty) {
        requestBody['promo_code'] = promoCode;
      }
      if (giftCard.isNotEmpty) {
        requestBody['gift_card'] = giftCard;
      }
      requestBody['address_id'] = addressId;
      requestBody['rush_delivery'] = rushDelivery ? 1 : 0;
      requestBody['use_wallet'] = useWallet ? 1 : 0;
      if (orderNote.isNotEmpty) {
        requestBody['order_note'] = orderNote;
      }

      if (deliveryTimeSlotId != null) {
        final parsedId = int.tryParse(deliveryTimeSlotId);
        if (parsedId != null) {
          requestBody['delivery_time_slot_id'] = parsedId;
        } else {
          requestBody['delivery_slot'] = deliveryTimeSlotId;
        }
      }

      if (usedAmountValue != null) {
        requestBody['used_amount_value'] = usedAmountValue.round();
      }

      if (paymentType != 'flutterwave') {
        requestBody['redirect_url'] = AppConstant.baseUrl;
      }

      if (paymentType == 'wallet') {
        requestBody['transaction_id'] = "";
      }

      if (paymentDetails != null) {
        for (var entry in paymentDetails.entries) {
          if (entry.value != null && entry.value.toString().isNotEmpty) {
            requestBody[entry.key] = entry.value.toString();
          }
        }
      }

      log('🟢 CREATE ORDER REQUEST BODY: $requestBody', name: 'OrderRepo');

      dynamic finalData;
      if (attachments.isEmpty) {
        finalData = requestBody;
      } else {
        finalData = dio.FormData.fromMap(requestBody);
        for (final entry in attachments.entries) {
          final productId = entry.key;
          final att = entry.value;

          if (att != null && att.filePath.isNotEmpty) {
            finalData.files.add(
              MapEntry(
                'attachments[$productId][]',
                await dio.MultipartFile.fromFile(
                  att.filePath,
                  filename: att.fileName,
                ),
              ),
            );
          }
        }
      }

      final customHeaders = Map<String, String>.from(headers ?? {});
      customHeaders.remove('Content-Type');

      final dioClient = dio.Dio(
        dio.BaseOptions(
          baseUrl: AppConstant.baseUrl,
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          headers: customHeaders,
        ),
      );

      final response = await dioClient.post(
        ApiRoutes.createOrderApi,
        data: finalData,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        log('❌ Order creation failed with status: ${response.statusCode}');
        log('📦 Error response: ${response.data}');
        String errorMessage = 'Something went wrong';
        if (response.data != null && response.data is Map) {
          errorMessage = response.data['message'] ??
              response.data['error'] ??
              'Something went wrong';
        }
        throw ApiException(errorMessage);
      }
    } on DioException catch (e) {
      log('❌ Dio Error: ${e.message}');
      log('📦 Error response: ${e.response?.data}');
      String errorMessage = 'Something went wrong';
      if (e.response?.data != null && e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ??
            e.response?.data['error'] ??
            e.message ??
            'Something went wrong';
      }
      throw ApiException(errorMessage);
    } catch (e) {
      log('❌ Catch Error: $e');
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchMyOrderList(
      {required int perPage, required int page}) async {
    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(
          '${ApiRoutes.getMyOrderApi}?page=$page&per_page=$perPage', {});
      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      throw ApiException('Failed to get my orders list');
    }
  }

  Future<List<OrderDetailModel>> getOrderDetail({
    required String orderSlug,
  }) async {
    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.orderDetailApi + orderSlug,
        {},
      );

      if (response.statusCode == 200) {
        final List<OrderDetailModel> orderData = [];
        orderData.add(OrderDetailModel.fromJson(response.data));
        return orderData;
      } else {
        return [];
      }
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<DeliveryBoyTrackingModel?> getDeliveryTracking({
    required String orderSlug,
  }) async {
    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(
        '${ApiRoutes.orderDetailApi}$orderSlug/delivery-boy-location',
        {},
      );

      if (response.statusCode == 200) {
        return DeliveryBoyTrackingModel.fromJson(response.data);
      } else {
        return null;
      }
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<String> downloadInvoicePdf(String invoiceUrl) async {
    try {
      final response =
          await AppConstant.apiBaseHelper.getAPICall(invoiceUrl, {});
      if (response.data != null) {
        if (Platform.isAndroid) {
          await Permission.storage.request();
        }
        // Get the appropriate directory
        Directory? directory;
        if (Platform.isAndroid) {
          // For Android - use Downloads directory
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else if (Platform.isIOS) {
          // For iOS - use Documents directory (accessible in Files app)
          directory = await getApplicationDocumentsDirectory();
        }
        final fileName = 'invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final filePath = '${directory!.path}/$fileName';
        await AppConstant.apiBaseHelper.downloadFile(
          url: invoiceUrl,
          cancelToken: CancelToken(),
          savePath: filePath,
          updateDownloadedPercentage: (received, total) {
            // Two parameters
            if (total != -1) {
              final percentage = (received / total * 100);
              log('Download: ${percentage.toStringAsFixed(0)}%');
            }
          },
        );
        return filePath;
      } else {
        return '';
      }
    } catch (e) {
      throw ApiException('Failed to download invoice: $e');
    }
  }

  Future<Map<String, dynamic>> returnOrderItemRequest({
    required int orderItemId,
    required String reason,
    List<XFile> images = const [],
  }) async {
    try {
      final form = await formDataWithImages(fields: {
        'reason': reason,
      }, images: images, imageFieldLabel: 'images');

      log('Return Order Item Request ${form.files}');

      final response = await AppConstant.apiBaseHelper.postAPICall(
          '${ApiRoutes.returnOrderItemApi}$orderItemId/return', form);
      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> cancelReturnRequest({
    required int orderItemId,
  }) async {
    try {
      final response = await AppConstant.apiBaseHelper.postAPICall(
          '${ApiRoutes.cancelReturnRequestApi}$orderItemId/return-cancel', {});

      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> cancelOrderItem({
    required int orderItemId,
  }) async {
    try {
      final response = await AppConstant.apiBaseHelper.postAPICall(
          '${ApiRoutes.cancelOrderItemApi}$orderItemId/cancel',
          {'reason': 'Cancellation request by user'});

      if (response.statusCode == 200) {
        return response.data;
      }
      return {
        'success': false,
        'message':
            'Failed to cancel the item. Server returned status: ${response.statusCode}'
      };
    } catch (e) {
      log('Error cancelling item: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
