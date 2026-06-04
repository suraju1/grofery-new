import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:grofery_user/screens/cart_page/model/get_cart_model.dart';
import 'package:grofery_user/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:grofery_user/screens/cart_page/repo/cart_repository.dart';
import 'package:grofery_user/bloc/user_cart_bloc/user_cart_event.dart';
import 'package:grofery_user/model/user_cart_model/user_cart.dart';
import 'package:grofery_user/services/user_cart/user_cart_local.dart';
import 'package:grofery_user/services/user_cart/user_cart_remote.dart';
import 'package:grofery_user/screens/cart_page/widgets/cart_product_item.dart';

part 'get_user_cart_state.dart';
part 'get_user_cart_event.dart';

class GetUserCartBloc extends Bloc<GetUserCartEvent, GetUserCartState> {
  GetUserCartBloc(this.cartBloc) : super(GetUserCartInitial()) {
    on<FetchUserCart>(_onFetchUserCart);
    on<RefreshUserCart>(_onRefreshUserCart);
    on<SyncCart>(_onSyncCart);
    on<SyncServerCartToLocal>(_onSyncServerCartToLocal);
  }

  final CartRepository repository = CartRepository();
  final localRepo = CartLocalRepository(Hive.box<UserCart>('cartBox'));
  final CartBloc cartBloc;
  final CartBloc localCartBloc = CartBloc(
      CartLocalRepository(Hive.box<UserCart>('cartBox')),
      CartRemoteRepository());
  List<GetCartModel> cartData = [];
  bool isUpdated = false;
  List<String> productSlug = [];
  int totalCartItems = 0;

  Future<void> _onFetchUserCart(
      FetchUserCart event, Emitter<GetUserCartState> emit) async {
    if (event.isRefresh != true) {
      emit(GetUserCartLoading());
    }
    try {
      debugPrint(
          "DEBUG_API: [GetUserCartBloc._onFetchUserCart] Event received, isRefresh: ${event.isRefresh}");
      debugPrint('🛒 [GetUserCartBloc] Fetching cart... isRefresh: ${event.isRefresh}, addressId: ${event.addressId}');
      final getCartData = await repository.getCartItems(
          addressId: event.addressId,
          promoCode: event.promoCode,
          rushDelivery: event.rushDelivery,
          useWallet: event.useWallet);

      cartData = getCartData;
      debugPrint('🛒 [GetUserCartBloc] Received response. List length: ${cartData.length}');
      
      if (cartData.isNotEmpty) {
         debugPrint('🛒 [GetUserCartBloc] success: ${cartData.first.success}, data: ${cartData.first.data != null}, items: ${cartData.first.data?.items?.length}');
      }

      if (cartData.isEmpty) {
        emit(GetUserCartFailed(error: "No cart data"));
        return;
      }

      final isCartEmpty = cartData.first.data == null ||
          cartData.first.data?.items == null ||
          cartData.first.data!.items!.isEmpty;

      if (isCartEmpty) {
        debugPrint("🛒 [GetUserCartBloc] Cart is empty.");
        if (event.isRefresh == true) {
          localRepo.syncServerCartToLocal([]);
          cartBloc.add(LoadCart());
          localCartBloc.add(LoadCart());
          debugPrint('🔄 [isRefresh=true] Cleared local cart state');
        }
        totalCartItems = 0;
        emit(GetUserCartLoaded(
          cartData: cartData,
          message: cartData.first.message ?? 'Cart is empty',
        ));
        return;
      }

      if (getCartData.first.success == true || cartData.first.data?.items != null) {
        debugPrint("🛒 SERVER ITEMS => ${cartData.first.data?.items?.length}");
        if (cartData.isNotEmpty && cartData.first.data!.items!.isNotEmpty) {
          productSlug = cartData.first.data!.items!
              .map((item) => item.product?.slug ?? '')
              .toList();
        }

        // ✅ FIX: isRefresh == true means user explicitly refreshed (e.g. cart page pull-to-refresh)
        // In that case, sync server → local to get fresh data.
        // isRefresh == false (default) means this was triggered silently in background
        // (e.g. home page tab switch). In that case, DO NOT overwrite local state
        // because the user may have just added an item optimistically.
        if (event.isRefresh == true) {
          if (cartData.isNotEmpty && cartData.first.data?.items != null) {
            final serverItems = cartData.first.data!.items!;

            debugPrint(
                '🔄 [isRefresh=true] Syncing ${serverItems.length} server items to local');

            final serverItemsList = serverItems.map((item) {
              final product = item.product;
              final variant = item.variant;

              final tieredPricingList = variant?.tieredPricing
                      ?.map((tier) => {
                            'min_qty': tier.minQty,
                            'price': tier.price,
                          })
                      .toList() ??
                  [];

              final mapped = {
                'id': item.id,
                'product_id': item.product?.id,
                'product_variant_id': item.productVariantId,
                'variant_name': item.variant?.title ?? '',
                'store_id': item.storeId,
                'product_name': product?.name ?? variant?.title ?? '',
                'image': product?.image ?? variant?.image ?? '',
                'price': variant?.price ?? 0,
                'special_price': variant?.specialPrice ?? 0,
                'quantity': item.quantity,
                'stock': variant?.stock ?? 0,
                'tiered_pricing': tieredPricingList,
              };

              debugPrint(
                  '🔍 Mapping server item: ${item.product?.id}_${item.productVariantId} → id: ${item.id}, qty: ${item.quantity}');
              return mapped;
            }).toList();

            await Future.delayed(const Duration(milliseconds: 150));

            try {
              localRepo.syncServerCartToLocal(serverItemsList);
              debugPrint('✅ Server cart synced to local storage');

              await Future.delayed(const Duration(milliseconds: 150));
              cartBloc.add(LoadCart());
              debugPrint('🔄 CartBloc reloaded after sync');
            } catch (syncError, stackTrace) {
              debugPrint('❌ Sync failed: $syncError');
              debugPrint('Stack: $stackTrace');
            }

            productSlug =
                serverItems.map((item) => item.product?.slug ?? '').toList();
          } else {
            debugPrint('⚠️ No items to sync');
          }
        } else {
          // ✅ FIX: isRefresh == false → background fetch, do NOT sync to local
          // Local Hive state is already up-to-date from CartBloc optimistic updates
          // Syncing here would OVERWRITE newly added items and cause them to disappear
          debugPrint(
              '✅ [isRefresh=false] Skipping local sync — preserving optimistic local state');

          if (cartData.isNotEmpty && cartData.first.data?.items != null) {
            productSlug = cartData.first.data!.items!
                .map((item) => item.product?.slug ?? '')
                .toList();
          }
        }

        totalCartItems = cartData.first.data!.itemsCount ?? 0;
        emit(GetUserCartLoaded(
          cartData: cartData,
          message: cartData.first.message ?? '',
        ));

        // ✅ FIX: Only reload CartBloc from local when explicitly refreshing
        // Otherwise local state is already correct
        if (event.isRefresh == true) {
          localCartBloc.add(LoadCart());
          debugPrint('🔄 Triggered CartBloc reload (isRefresh=true)');
        }
      } else {
        emit(GetUserCartLoaded(
            cartData: cartData, message: getCartData.first.message ?? ''));
      }
    } catch (e) {
      emit(GetUserCartFailed(error: e.toString()));
    }
  }

  Future<void> _onRefreshUserCart(
      RefreshUserCart event, Emitter<GetUserCartState> emit) async {
    try {
      emit(GetUserCartInitial());
      Future.microtask(() {
        add(FetchUserCart(
            addressId: event.addressId,
            promoCode: event.promoCode,
            rushDelivery: event.rushDelivery,
            useWallet: event.useWallet,
            isRefresh: true)); // ✅ isRefresh: true so it properly syncs
      });
    } catch (e) {
      emit(GetUserCartFailed(error: e.toString()));
    }
  }

  Future<void> _onSyncCart(
    SyncCart event,
    Emitter<GetUserCartState> emit,
  ) async {
    emit(UserCartInitialLoading());

    try {
      final response = await repository.syncCart(
        items: localRepo.createSyncPayload(),
      );

      debugPrint("🛒 SYNC CART RESPONSE => ${response.toString()}");

      if (response['success'] == true) {
        add(
          FetchUserCart(
            isRefresh: true,
          ),
        );
      } else {
        emit(
          GetUserCartFailed(
            error: response['message']?.toString() ?? "Cart sync failed",
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint("❌ SYNC CART ERROR => $e");
      debugPrint(stackTrace.toString());

      emit(
        GetUserCartFailed(
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSyncServerCartToLocal(
    SyncServerCartToLocal event,
    Emitter<GetUserCartState> emit,
  ) async {
    debugPrint('🔄 Manual sync triggered');

    if (event.serverItems.isEmpty) {
      debugPrint('⚠️ No server items to sync');
      return;
    }

    try {
      localRepo.syncServerCartToLocal(event.serverItems);
      cartBloc.add(LoadCart());
      debugPrint('🔄 CartBloc reloaded after manual sync');
    } catch (e) {
      debugPrint('❌ Manual sync failed: $e');
    }
  }
}
