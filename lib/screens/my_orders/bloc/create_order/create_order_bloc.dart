import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cart_page/widgets/cart_product_item.dart';
import '../../repo/order_repo.dart';

part 'create_order_event.dart';
part 'create_order_state.dart';

class CreateOrderBloc extends Bloc<CreateOrderEvent, CreateOrderState> {
  CreateOrderBloc() : super(CreateOrderInitial()) {
    on<CreateOrderRequest>(_onCreateOrderRequest);
  }
  final OrderRepository repository = OrderRepository();

  bool isLoading = false;

  Future<void> _onCreateOrderRequest(CreateOrderRequest event, Emitter<CreateOrderState> emit) async {
    emit(CreateOrderProgress());
    isLoading = true;
    try{
      final response = await repository.createOrder(
        paymentType: event.paymentType,
        promoCode: event.promoCode ?? '',
        giftCard: event.giftCard ?? '',
        addressId: event.addressId,
        rushDelivery: event.rushDelivery ?? false,
        useWallet: event.useWallet ?? false,
        orderNote: event.orderNote ?? '',
        paymentDetails: event.paymentDetails,
        attachments: event.attachments!,
        usedAmountValue: event.usedAmountValue,
        deliveryTimeSlotId: event.deliveryTimeSlotId,
      );

      print('📦 Create Order Response: $response');

      if (response['success'] == true) {
        isLoading = false;
        emit(CreateOrderSuccess(
            message: response['message'],
            orderSlug: response['data']['slug'],
            paymentUrl: event.paymentType == 'flutterwave'
                ? response['data']['payment_response']['link']
                : ''));
      } else {
        isLoading = false;
        emit(CreateOrderFailure(error: response['message'] ?? 'Something went wrong (Success False)'));
      }
    } catch(e) {
      isLoading = false;
      emit(CreateOrderFailure(error: e.toString()));
    }
  }
}
