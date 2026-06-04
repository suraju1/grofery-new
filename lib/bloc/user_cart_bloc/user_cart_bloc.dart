import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grofery_user/bloc/user_cart_bloc/user_cart_event.dart';
import 'package:grofery_user/bloc/user_cart_bloc/user_cart_state.dart';

import '../../config/global.dart';
import '../../model/user_cart_model/cart_sync_action.dart';
import '../../screens/cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import '../../services/user_cart/user_cart_local.dart';
import '../../services/user_cart/user_cart_remote.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartLocalRepository localRepo;
  final CartRemoteRepository remoteRepo;

  Timer? _debounce;

  CartBloc(this.localRepo, this.remoteRepo) : super(CartInitial()) {
    on<LoadCart>(_onLoadCart);
    on<AddToCart>(_onAddToCart);
    on<UpdateCartQty>(_onUpdateQty);
    on<RemoveFromCart>(_onRemoveItem);
    on<RemoveLocally>(_onRemoveLocally);
    on<ClearCart>(_onClearCart);
    on<SyncLocalCart>(_onSyncLocalCart);
  }

  void _onLoadCart(LoadCart event, Emitter<CartState> emit) {
    emit(CartLoading(items: localRepo.getAllItems()));
    emit(CartLoaded(localRepo.getAllItems()));
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    debugPrint('ADD → ${event.item.productId} ${event.item.variantId}');
    final bool isLoggedIn = Global.userData != null && Global.token!.isNotEmpty;

    if (isLoggedIn) {
      localRepo.addItem(event.item);
      _debouncedSync(
        context: event.context,
        addressId: event.addressId,
        promoCode: event.promoCode,
        rushDelivery: event.rushDelivery,
        useWallet: event.useWallet,
        isFromCartPage: event.isFromCartPage,
      );
    } else {
      localRepo.addItemGuest(event.item);
    }

    emit(CartLoaded(localRepo.getAllItems()));
  }

  void _onUpdateQty(UpdateCartQty event, Emitter<CartState> emit) {
    log('Update Quantity');
    final bool isLoggedIn = Global.userData != null;

    if (isLoggedIn) {
      localRepo.updateQuantity(event.cartKey, event.quantity);
      _debouncedSync(
        context: event.context,
        addressId: event.addressId,
        promoCode: event.promoCode,
        rushDelivery: event.rushDelivery,
        useWallet: event.useWallet,
        isFromCartPage: event.isFromCartPage,
      );
    } else {
      localRepo.updateQuantityGuest(event.cartKey, event.quantity);
    }

    emit(CartLoaded(localRepo.getAllItems()));
  }

  void _onRemoveItem(RemoveFromCart event, Emitter<CartState> emit) {
    debugPrint('🗑 REMOVE → ${event.cartKey}');
    final bool isLoggedIn = Global.userData != null && Global.token!.isNotEmpty;

    if (isLoggedIn) {
      localRepo.markForDelete(event.cartKey);
      _debouncedSync(
        context: event.context,
        addressId: event.addressId,
        promoCode: event.promoCode,
        rushDelivery: event.rushDelivery,
        useWallet: event.useWallet,
        isFromCartPage: event.isFromCartPage,
      );
    } else {
      localRepo.removeItemGuest(event.cartKey);
    }

    emit(CartLoaded(localRepo.getAllItems()));
  }

  void _onRemoveLocally(RemoveLocally event, Emitter<CartState> emit) {
    debugPrint('🗑 REMOVE LOCALLY → ${event.cartKey}');
    localRepo.deleteLocally(event.cartKey);
    emit(CartLoaded(localRepo.getAllItems()));
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(CartLoading(items: localRepo.getAllItems()));
    debugPrint('🧹 CLEAR CART');
    localRepo.clearLocalCart();
    emit(CartLoaded([]));
    _debouncedSync(context: event.context);
  }

  void _debouncedSync({
    required BuildContext context,
    int? addressId,
    String? promoCode,
    bool? rushDelivery,
    bool? useWallet,
    bool? isFromCartPage,
  }) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      add(SyncLocalCart(
        context: context,
        addressId: addressId,
        promoCode: promoCode,
        rushDelivery: rushDelivery,
        useWallet: useWallet,
        isFromCartPage: isFromCartPage,
      ));
    });
  }

  Future<void> _onSyncLocalCart(
    SyncLocalCart event,
    Emitter<CartState> emit,
  ) async {
    final pendingItems = localRepo.getPendingSyncItems();

    if (pendingItems.isEmpty) {
      debugPrint('✅ SYNC → Nothing to sync');
      return;
    }

    debugPrint('🌐 SYNC START → ${pendingItems.length} items');

    bool hadAddFailure = false;
    String? lastErrorMessage;

    for (final item in pendingItems) {
      try {
        debugPrint(
            '🔄 Processing sync for ${item.cartKey} | Action: ${item.syncAction} | ServerID: ${item.serverCartItemId}');

        switch (item.syncAction) {
          case CartSyncAction.add:
            debugPrint(
                '🌐 ADD API → ${item.cartKey} | hasTiers: ${item.tieredPricing?.isNotEmpty}');

            final Map<String, dynamic> body = {
              'product_variant_id': int.parse(item.variantId),
              'store_id': int.parse(item.vendorId),
              'quantity': item.quantity,
            };

            if (item.tieredPricing != null && item.tieredPricing!.isNotEmpty) {
              final applicableTiers = item.tieredPricing!
                  .where((t) => item.quantity >= t.minQty)
                  .toList();

              if (applicableTiers.isNotEmpty) {
                applicableTiers.sort((a, b) => b.minQty.compareTo(a.minQty));
                final bestTier = applicableTiers.first;
                body['tiered_pricing'] = [
                  {'price': bestTier.price, 'quantity': bestTier.minQty}
                ];
                debugPrint(
                    '🎯 SYNC ADD → Tier Selected: ${bestTier.minQty} pcs at ₹${bestTier.price}');
              }
            }

            print("📤 FINAL REQUEST BODY (ADD) → $body");

            final res = await remoteRepo.addItemToCart(body: body);

            if (res['success'] == true && res['data'] != null) {
              final dynamic data = res['data'];
              int? serverCartItemId;

              if (data is Map) {
                if (data['items'] is List) {
                  // Shape 1: data is CartData map containing "items" list
                  final itemsList = data['items'] as List;
                  final addedServerItem = itemsList.firstWhere(
                    (serverItem) =>
                        serverItem['product_id']?.toString() ==
                            item.productId &&
                        serverItem['product_variant_id']?.toString() ==
                            item.variantId &&
                        serverItem['store_id']?.toString() == item.vendorId,
                    orElse: () => null,
                  );
                  if (addedServerItem != null) {
                    serverCartItemId =
                        int.tryParse(addedServerItem['id']?.toString() ?? '');
                  }
                } else if (data['product_variant_id'] != null) {
                  // Shape 2: data is the single added cart item itself
                  if (data['product_variant_id']?.toString() ==
                      item.variantId) {
                    serverCartItemId =
                        int.tryParse(data['id']?.toString() ?? '');
                  }
                }
              } else if (data is List) {
                // Shape 3: data is a list of cart items directly
                final addedServerItem = data.firstWhere(
                  (serverItem) =>
                      serverItem['product_id']?.toString() == item.productId &&
                      serverItem['product_variant_id']?.toString() ==
                          item.variantId &&
                      serverItem['store_id']?.toString() == item.vendorId,
                  orElse: () => null,
                );
                if (addedServerItem != null) {
                  serverCartItemId =
                      int.tryParse(addedServerItem['id']?.toString() ?? '');
                }
              }

              if (serverCartItemId != null) {
                localRepo.markSynced(
                  item.cartKey,
                  serverCartItemId: serverCartItemId,
                );
                debugPrint(
                    '✅ ADD synced locally with serverCartItemId: $serverCartItemId');
              } else {
                debugPrint(
                    '⚠️ Could not find matching item in server response: $data');
                // Self-healing fallback: The call succeeded on the server, so mark as synced.
                // The correct serverCartItemId will be fetched on next background getCart fetch.
                localRepo.markSynced(item.cartKey);
                debugPrint(
                    '✅ ADD marked synced as fallback (without serverCartItemId)');
              }
            } else {
              final errorMessage =
                  res['message'] as String? ?? 'Failed to add item to cart';

              debugPrint('❌ ADD API failed → $errorMessage');
              localRepo.deleteLocally(item.cartKey);
              hadAddFailure = true;
              lastErrorMessage = errorMessage;
            }
            break;

          case CartSyncAction.update:
            final freshItem = localRepo.getItemByKey(item.cartKey);
            log('OFIEFBN');
            if (freshItem == null) {
              debugPrint(
                  '❌ Item disappeared from local storage: ${item.cartKey}');
              break;
            }

            if (freshItem.serverCartItemId == null) {
              debugPrint('❌ No serverCartItemId yet for ${item.cartKey}');
              debugPrint('   Current syncAction: ${freshItem.syncAction}');
              debugPrint('   Quantity: ${freshItem.quantity}');
              debugPrint('   Will retry on next sync');
              break;
            }

            debugPrint(
                '🌐 UPDATE API → ${item.cartKey} (qty: ${freshItem.quantity}, serverCartItemId: ${freshItem.serverCartItemId}, hasTiers: ${freshItem.tieredPricing?.isNotEmpty})');

            final Map<String, dynamic> updateBody = {
              'quantity': freshItem.quantity,
            };

            if (freshItem.tieredPricing != null &&
                freshItem.tieredPricing!.isNotEmpty) {
              final applicableTiers = freshItem.tieredPricing!
                  .where((t) => freshItem.quantity >= t.minQty)
                  .toList();

              if (applicableTiers.isNotEmpty) {
                applicableTiers.sort((a, b) => b.minQty.compareTo(a.minQty));
                final bestTier = applicableTiers.first;
                updateBody['tiered_pricing'] = [
                  {'price': bestTier.price, 'quantity': bestTier.minQty}
                ];
                debugPrint(
                    '🎯 SYNC UPDATE → Tier Selected: ${bestTier.minQty} pcs at ₹${bestTier.price}');
              }
            }

            print("📤 FINAL REQUEST BODY (UPDATE) → $updateBody");

            try {
              await remoteRepo.updateItemQuantity(
                cartItemId: freshItem.serverCartItemId!,
                body: updateBody,
              );

              localRepo.markSynced(item.cartKey);
              debugPrint(
                  '✅ UPDATE successful → qty: ${freshItem.quantity}, serverId: ${freshItem.serverCartItemId}');
            } catch (e) {
              debugPrint('❌ UPDATE API failed → $e');
            }
            break;

          case CartSyncAction.delete:
            debugPrint(
                '🌐 DELETE API → ${item.cartKey} (serverCartItemId: ${item.serverCartItemId})');

            if (item.serverCartItemId != null) {
              try {
                await remoteRepo.removeItemFromCart(
                  cartItemId: item.serverCartItemId!,
                );
                debugPrint('✅ DELETE API successful → ${item.cartKey}');
              } catch (e) {
                debugPrint('❌ DELETE API failed → $e');
              }
            }

            localRepo.removeLocal(item.cartKey);
            debugPrint('✅ Removed locally → ${item.cartKey}');
            break;

          case CartSyncAction.none:
            break;
        }
      } catch (e, stackTrace) {
        debugPrint('❌ SYNC FAILED → ${item.cartKey} → $e');
        debugPrint('Stack trace: ${stackTrace.toString()}');
        continue;
      }
    }

    debugPrint('✅ SYNC COMPLETE');

    if (hadAddFailure && lastErrorMessage != null) {
      emit(CartLoaded(localRepo.getAllItems(), errorMessage: lastErrorMessage));
    } else {
      emit(CartLoaded(localRepo.getAllItems()));
    }

    // if (event.context.mounted) {
    //   event.context.read<GetUserCartBloc>().add(
    //         FetchUserCart(
    //           addressId: event.addressId,
    //           promoCode: event.promoCode,
    //           rushDelivery: event.rushDelivery,
    //           useWallet: event.useWallet,
    //           isRefresh: true,
    //         ),
    //       );
    // }

    if (hadAddFailure) {
      debugPrint(
          '⚠️ Skipping GetUserCartBloc fetch due to ADD failure — local state is source of truth');
      return;
    }

    // ✅ FIX: Sirf Cart Page pe hi server se fetch karo
    // Product listing screen pe GetUserCartBloc.FetchUserCart() NAHI chalega
    // Kyunki woh local optimistic state ko overwrite kar deta tha
    // aur item 1-2 seconds me disappear ho jata tha
    if (event.isFromCartPage == true) {
      if (event.context.mounted) {
        event.context.read<GetUserCartBloc>().add(
              FetchUserCart(
                addressId: event.addressId,
                rushDelivery: event.rushDelivery,
                useWallet: event.useWallet,
                promoCode: event.promoCode,
                isRefresh: true,
              ),
            );
      }
    } else {
      // 🚫 REMOVED: FetchUserCart() call jo item disappear karta tha
      // Local Hive state already correct hai markSynced() ke baad
      debugPrint(
          '✅ Skipping server fetch on product listing — local state is source of truth');
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
