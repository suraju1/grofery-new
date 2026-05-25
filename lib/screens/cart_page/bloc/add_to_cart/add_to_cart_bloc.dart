import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grofery_user/config/settings_data_instance.dart';
import '../../repo/cart_repository.dart';
import 'add_to_cart_event.dart';
import 'add_to_cart_state.dart';


class AddToCartBloc extends Bloc<AddToCartEvent, AddToCartState> {
  AddToCartBloc() : super(AddToCartInitial()) {
    on<AddItemToCart>(_onAddItemToCart);
  }

  final CartRepository repository = CartRepository();

  Future<void> _onAddItemToCart(AddItemToCart event, Emitter<AddToCartState> emit) async {
    final systemSettings = SettingsData.instance.system;
    if (systemSettings != null && systemSettings.isTodayHoliday) {
      emit(AddToCartFailed(error: systemSettings.vacationMessage));
      return;
    }

    emit(AddToCartLoading());
    try {
      final response = await repository.addItemToCart(
        productVariantId: event.productVariantId,
        storeId: event.storeId,
        quantity: event.quantity,
      );

      if(response['success']== true){
        emit(AddToCartSuccess());
        Future.microtask((){});
      } else {
        emit(AddToCartFailed(error: response['message']));
      }
    }catch(e){
      emit(AddToCartFailed(error: e.toString()));
    }
  }
}
