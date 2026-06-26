import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:grofery_user/bloc/settings_bloc/settings_bloc.dart';
import 'package:grofery_user/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:grofery_user/bloc/user_cart_bloc/user_cart_event.dart';
import 'package:grofery_user/config/settings_data_instance.dart';
import 'package:grofery_user/config/theme.dart';
import 'package:grofery_user/config/payment_config.dart';
import 'package:grofery_user/screens/cart_page/bloc/clear_cart/clear_cart_bloc.dart';
import 'package:grofery_user/screens/cart_page/bloc/clear_cart/clear_cart_event.dart';
import 'package:grofery_user/screens/cart_page/bloc/remove_item_from_cart/remove_item_from_cart_bloc.dart';
import 'package:grofery_user/screens/cart_page/bloc/remove_item_from_cart/remove_item_from_cart_event.dart';
import 'package:grofery_user/screens/cart_page/bloc/update_item_quantity/update_item_quantity_bloc.dart';
import 'package:grofery_user/screens/cart_page/bloc/update_item_quantity/update_item_quantity_event.dart';
import 'package:grofery_user/screens/cart_page/bloc/update_item_quantity/update_item_quantity_state.dart';
import 'package:grofery_user/screens/cart_page/bloc/remove_item_from_cart/remove_item_from_cart_state.dart';
import 'package:grofery_user/screens/cart_page/widgets/bill_summary_widget.dart';
import 'package:grofery_user/screens/cart_page/widgets/delivery_address_widget.dart';
import 'package:grofery_user/screens/cart_page/widgets/address_selection_bottom_sheet.dart';
import 'package:grofery_user/screens/product_detail_page/widgets/product_detail_shimmer.dart';
import 'package:grofery_user/utils/widgets/custom_button.dart';
import 'package:grofery_user/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:grofery_user/utils/widgets/custom_refresh_indicator.dart';
import 'package:grofery_user/utils/widgets/custom_scaffold.dart';
import 'package:grofery_user/utils/widgets/custom_toast.dart';
import '../../../bloc/user_cart_bloc/user_cart_state.dart';
import '../../../config/constant.dart';
import '../../../config/global.dart';
import '../../../services/address/selected_address_hive.dart';
import '../../../services/user_cart/cart_validation.dart';
import '../../../utils/widgets/whole_page_progress.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/widgets/minimum_order_progress_bar.dart';
import '../../my_orders/bloc/create_order/create_order_bloc.dart';
import '../../payment_options/bloc/payment_bloc.dart';
import '../../payment_options/bloc/payment_event.dart';
import '../../payment_options/bloc/payment_state.dart';
import '../../payment_options/widgets/webview_payment.dart';
import '../../product_detail_page/bloc/similar_product_bloc/similar_product_bloc.dart';
import '../../product_detail_page/model/product_detail_model.dart';
import '../../address_list_page/model/get_address_list_model.dart';
import '../../address_list_page/bloc/get_address_list_bloc/get_address_list_bloc.dart';
import '../../wallet_page/bloc/user_wallet/user_wallet_bloc.dart';
import '../../save_for_later_page/bloc/save_for_later_bloc/save_for_later_bloc.dart';
import '../../save_for_later_page/bloc/save_for_later_bloc/save_for_later_state.dart';
import '../../../router/app_routes.dart';
import '../bloc/attachment/attachment_bloc.dart';
import '../bloc/cart_ui_bloc/cart_ui_bloc.dart';
import '../bloc/cart_ui_bloc/cart_ui_event.dart';
import '../bloc/cart_ui_bloc/cart_ui_state.dart';
import '../bloc/get_user_cart/get_user_cart_bloc.dart';
import '../bloc/promo_code/promo_code_bloc.dart';
import '../bloc/promo_code/promo_code_event.dart';
import '../bloc/promo_code/promo_code_state.dart';
import '../bloc/validate_promo_code/validate_promo_code_bloc.dart';
import '../bloc/clear_cart/clear_cart_state.dart';
import '../model/get_cart_model.dart';
import '../widgets/cart_product_item.dart';
import '../widgets/delivery_time_slot_widget.dart';
import '../widgets/delivery_type_widget.dart';
import '../widgets/order_note_widget.dart';
import '../widgets/removed_items_widget.dart';
import '../widgets/wallet_usage_widget.dart';
import '../widgets/you_might_also_like_product_widget.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  AddressListData? selectedAddress;
  double totalAmount = 0.0;
  double itemsTotal = 0.0;
  String? selectedPaymentMethod;
  dynamic selectedPaymentMethodType;

  // FIX: Use a single loading flag managed only via setState in listeners/callbacks.
  // Never mutate this directly inside build().
  bool isCartLoading =
      true; //////////////////////////////////////////ha change kela aahe true hota pahile
  bool isClearingCart = false;
  bool isWholePageProgress = false;
  bool isBillDetailsLoading = false;
  DeliveryType selectedDeliveryType = DeliveryType.regular;
  int? cartId;
  late bool _userWantsWallet = false;

  // FIX: stateData is only ever updated inside setState() from the BlocListener,
  // never directly assigned inside build().
  List<GetCartModel> stateData = [];

  int? deliveryZoneId;
  int? previousDeliveryZoneId;
  String? promoCode;
  String orderNote = '';
  double walletAmountUsedValue = 0.0;
  double walletBalance = 0.0;
  final TextEditingController _promoController = TextEditingController();
  TimeSlot? selectedTimeSlot;

  // Calculated totals for UI consistency
  double calculatedItemsTotal = 0.0;
  double originalItemsTotal = 0.0;
  double itemSavings = 0.0;
  double currentDeliveryCharge = 0.0;
  double rushCharge = 99.0;
  bool hasRetriedFetch = false;

  @override
  void initState() {
    super.initState();
    _userWantsWallet = false;
    //context.read<GetUserCartBloc>().add(FetchUserCart());///////////////////// he old line ahe
    Future.microtask(() {
      context.read<GetUserCartBloc>().add(FetchUserCart());
    });
    context.read<SettingsBloc>().add(FetchSettingsData(context: context));
    context.read<SimilarProductBloc>().add(FetchSimilarProduct(
        excludeProductSlug: context.read<GetUserCartBloc>().productSlug));
    context.read<PromoCodeBloc>().add(RemovePromoCode());
    context.read<UserWalletBloc>().add(FetchUserWallet());
    context.read<AttachmentBloc>().add(ClearAllAttachments());

    final walletState = context.read<UserWalletBloc>().state;
    if (walletState is UserWalletLoaded && walletState.userWallet.isNotEmpty) {
      walletBalance =
          double.tryParse(walletState.userWallet.first.balance ?? '0.0') ?? 0.0;
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  bool get canUseWallet {
    return Global.userData != null;
  }

  bool get effectiveUseWallet => canUseWallet && _userWantsWallet;

  void _refreshCart({bool resetWalletPreference = false}) {
    if (resetWalletPreference) {
      _userWantsWallet = false;
    }
    context.read<GetUserCartBloc>().add(
          FetchUserCart(
            addressId: selectedAddress?.id,
            rushDelivery: selectedDeliveryType == DeliveryType.rush,
            useWallet: effectiveUseWallet,
            promoCode: promoCode,
          ),
        );
  }

  void _calculateTotals(List<GetCartModel> cartData) {
    if (cartData.isEmpty || cartData.first.data?.items == null) {
      setState(() {
        stateData = cartData;
        itemsTotal = 0;
        totalAmount = 0;
        calculatedItemsTotal = 0;
        originalItemsTotal = 0;
        itemSavings = 0;
        currentDeliveryCharge = 0;
        walletAmountUsedValue = 0;
        isCartLoading = false;
      });
      return;
    }

    final data = cartData.first.data!;
    final billSummaryData = data.paymentSummary;

    cartId = data.id;
    final newDeliveryZoneId = data.deliveryZone?.zoneId;

    if (newDeliveryZoneId != null &&
        newDeliveryZoneId != previousDeliveryZoneId) {
      deliveryZoneId = newDeliveryZoneId;
      previousDeliveryZoneId = newDeliveryZoneId;
      context
          .read<GetAddressListBloc>()
          .add(FetchUserAddressList(deliveryZoneId: deliveryZoneId));
    } else {
      deliveryZoneId = newDeliveryZoneId;
    }

    double rawTotalAmount = billSummaryData?.payableAmount?.toDouble() ?? 0.0;
    double rawWalletUsed = billSummaryData?.walletAmountUsed?.toDouble() ?? 0.0;
    double backendItemsTotal = billSummaryData?.itemsTotal?.toDouble() ?? 0.0;
    double curDeliveryCharge = billSummaryData?.deliveryCharges?.toDouble() ?? 0.0;

    debugPrint('DEBUG_TOTALS: payableAmount=$rawTotalAmount, deliveryCharges=$curDeliveryCharge, itemsTotal=$backendItemsTotal, useWallet=${billSummaryData?.useWallet}, walletAmountUsed=$rawWalletUsed');

    double origItemsTotal = 0;
    for (var item in data.items!) {
      origItemsTotal += (item.variant?.price ?? 0) * (item.quantity ?? 1);
    }

    double savings = origItemsTotal - backendItemsTotal;
    if (savings < 0) savings = 0;

    double rCharge = data.deliveryZone?.rushDeliveryCharges?.toDouble() ?? 99.0;
    if (rCharge < 99.0) rCharge = 99.0;

    // FIX: stateData is updated here inside setState — the single source of truth.
    setState(() {
      stateData = cartData;
      itemsTotal = backendItemsTotal;
      totalAmount = rawTotalAmount;
      calculatedItemsTotal = backendItemsTotal;
      originalItemsTotal = origItemsTotal;
      itemSavings = savings;
      currentDeliveryCharge = curDeliveryCharge;
      rushCharge = rCharge;
      walletAmountUsedValue = rawWalletUsed;
      isCartLoading = false;

      // Sync wallet selection with backend's use_wallet response
      _userWantsWallet = billSummaryData?.useWallet ?? false;

      // Sync promoCode with backend's response so it doesn't get lost on page reload
      promoCode = billSummaryData?.promoCode;
      if (promoCode != null && promoCode!.isNotEmpty) {
        _promoController.text = promoCode!;
      } else {
        _promoController.clear();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (BuildContext context, PaymentState paymentState) {
        return Stack(
          children: [
            CustomScaffold(
              showViewCart: false,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              title: l10n?.cart ?? 'Cart',
              appBarActions: [
                // Clear-cart button — reads from stateData, no bloc needed here
                if (stateData.isNotEmpty && stateData.first.data?.items != null)
                  Container(
                    padding: const EdgeInsets.only(right: 10),
                    child: TextButton(
                      onPressed: () async {
                        final shouldClear =
                            await _showClearCartConfirmDialog(context);
                        if (shouldClear && context.mounted) {
                          context.read<ClearCartBloc>().add(ClearCartRequest());
                          context
                              .read<CartBloc>()
                              .add(ClearCart(context: context));
                          Future.delayed(const Duration(milliseconds: 200), () {
                            if (context.mounted) {
                              context.read<GetUserCartBloc>().add(
                                    FetchUserCart(
                                      addressId: selectedAddress?.id,
                                      rushDelivery: selectedDeliveryType ==
                                          DeliveryType.rush,
                                      useWallet: _userWantsWallet,
                                      promoCode: promoCode,
                                    ),
                                  );
                            }
                          });
                        }
                      },
                      child: Text(
                        AppLocalizations.of(context)!.clearCart,
                        style: TextStyle(
                            color: AppTheme.primaryColor, fontSize: 14),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
              showAppBar: true,
              body: MultiBlocListener(
                listeners: [
                  BlocListener<SettingsBloc, SettingsState>(
                    listener: (context, settingsState) {
                      if (settingsState is SettingsLoaded) {
                        final walletAllowed =
                            SettingsData.instance.payment?.wallet ?? false;
                        if (!walletAllowed && _userWantsWallet) {
                          setState(() {
                            _userWantsWallet = false;
                          });
                          _refreshCart();
                        }
                      }
                    },
                  ),
                  BlocListener<CartBloc, CartState>(
                    listener: (context, cartState) {
                      if (cartState is CartLoaded &&
                          cartState.errorMessage != null) {
                        ToastManager.show(
                          context: context,
                          message: cartState.errorMessage!,
                          type: ToastType.error,
                        );
                        _refreshCart();
                      }
                    },
                  ),
                  BlocListener<GetAddressListBloc, GetAddressListState>(
                    listener: (context, addressState) {
                      if (addressState is GetAddressListLoaded &&
                          selectedAddress == null &&
                          addressState.addressList.isNotEmpty) {
                        setState(() {
                          selectedAddress = addressState.addressList.first;
                          isCartLoading = true;
                        });
                        HiveSelectedAddressHelper.setSelectedAddress(
                            addressState.addressList.first);
                        context.read<GetUserCartBloc>().add(FetchUserCart(
                              addressId: selectedAddress?.id,
                              rushDelivery:
                                  selectedDeliveryType == DeliveryType.rush,
                              useWallet: _userWantsWallet,
                              promoCode: promoCode,
                            ));
                      }
                    },
                  ),
                  // FIX: This is the ONLY place stateData and isCartLoading are updated.
                  BlocListener<GetUserCartBloc, GetUserCartState>(
                    listener: (context, state) {
                      developer.log('Get User Cart Bloc  $state');
                      if (state is GetUserCartLoaded) {
                        if (state.cartData.isNotEmpty &&
                            state.cartData.first.data?.items?.isNotEmpty ==
                                true) {
                          hasRetriedFetch = false;
                        }
                        // _calculateTotals calls setState internally and sets stateData.
                        _calculateTotals(state.cartData);
                        setState(() {
                          isBillDetailsLoading = false;
                        });
                        context.read<CartUIBloc>().add(SetWalletLoading(false));
                      } else if (state is GetUserCartLoading) {
                        if (stateData.isEmpty) {
                          setState(() {
                            isCartLoading = true;
                          });
                        }
                        context.read<CartUIBloc>().add(SetWalletLoading(false));
                      }
                      // else if (state is GetUserCartFailed) {
                      //   setState(() {
                      //     isCartLoading = false;
                      //   });
                      else if (state is GetUserCartFailed) {
                        debugPrint("❌ GetUserCartFailed");

                        setState(() {
                          isCartLoading = false;
                          isBillDetailsLoading = false;
                          // Instead of clearing stateData unconditionally, we leave it as is
                          // to prevent flickering if it was already populated,
                          // or let the fallback logic in _buildCartContent handle it.
                        });

                        context.read<CartUIBloc>().add(SetWalletLoading(false));
                      }
                    },
                  ),
                  BlocListener<RemoveItemFromCartBloc, RemoveItemFromCartState>(
                    listener: (context, state) {
                      if (state is RemoveItemFromCartLoading) {
                        // Do not show full screen loader
                      } else if (state is RemoveItemFromCartSuccess) {
                        context.read<GetUserCartBloc>().add(FetchUserCart(
                              addressId: selectedAddress?.id,
                              rushDelivery:
                                  selectedDeliveryType == DeliveryType.rush,
                              useWallet: _userWantsWallet,
                              promoCode: promoCode,
                              isRefresh: true,
                            ));
                      } else if (state is RemoveItemFromCartFailed) {
                        // Do not show full screen loader
                        context.read<GetUserCartBloc>().add(FetchUserCart(
                              addressId: selectedAddress?.id,
                              rushDelivery:
                                  selectedDeliveryType == DeliveryType.rush,
                              useWallet: _userWantsWallet,
                              promoCode: promoCode,
                              isRefresh: true,
                            ));
                      }
                    },
                  ),
                  BlocListener<ClearCartBloc, ClearCartState>(
                    listener: (context, state) {
                      if (state is ClearCartLoading) {
                        setState(() {
                          isCartLoading = true;
                          isClearingCart = true;
                        });
                      } else if (state is ClearCartSuccess ||
                          state is ClearCartFailed) {
                        setState(() {
                          isCartLoading = false;
                          isClearingCart = false;
                        });
                      }
                    },
                  ),
                  BlocListener<SaveForLaterBloc, SaveForLaterState>(
                    listener: (context, state) {
                      if (state is SaveForLaterLoading) {
                        setState(() {
                          isCartLoading = true;
                        });
                      } else if (state is ProductSavedSuccess) {
                        setState(() {
                          isCartLoading = false;
                        });
                        ToastManager.show(
                            context: context,
                            message: '${state.productName} is saved for later');
                        context.read<GetUserCartBloc>().add(FetchUserCart(
                              addressId: selectedAddress?.id,
                              rushDelivery:
                                  selectedDeliveryType == DeliveryType.rush,
                              useWallet: _userWantsWallet,
                              promoCode: promoCode,
                            ));
                      } else if (state is SaveForLaterFailed) {
                        setState(() {
                          isCartLoading = false;
                        });
                      }
                    },
                  ),
                  BlocListener<CreateOrderBloc, CreateOrderState>(
                    listener: (context, state) {
                      if (state is CreateOrderSuccess) {
                        context
                            .read<CartUIBloc>()
                            .add(SetWholePageProgress(true));
                        context.read<CartUIBloc>().add(SetWalletLoading(false));
                        setState(() {
                          isWholePageProgress = true;
                          isCartLoading = true;
                        });
                        if (selectedPaymentMethodType ==
                            PaymentMethodType.flutterwave) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => WebViewPaymentPage(
                                        paymentUrl: state.paymentUrl!,
                                        onPaymentSuccess: () {
                                          setState(() {
                                            isWholePageProgress = false;
                                            isCartLoading = false;
                                          });
                                        },
                                        onPaymentFailure: () {
                                          setState(() {
                                            isWholePageProgress = false;
                                            isCartLoading = false;
                                          });
                                          context
                                              .read<GetUserCartBloc>()
                                              .add(FetchUserCart(
                                                addressId: selectedAddress?.id,
                                                rushDelivery:
                                                    selectedDeliveryType ==
                                                        DeliveryType.rush,
                                                useWallet: _userWantsWallet,
                                                promoCode: promoCode,
                                              ));
                                        },
                                      )));
                        } else {
                          final displayAddress = selectedAddress != null
                              ? formatAddressFromModel(selectedAddress!)
                              : null;
                          GoRouter.of(context).pop();
                          GoRouter.of(context).push(
                            AppRoutes.orderSuccess,
                            extra: {
                              'address': displayAddress,
                              'addressType': selectedAddress!.addressType,
                              'orderSlug': state.orderSlug,
                            },
                          );
                        }
                      } else if (state is CreateOrderFailure) {
                        setState(() {
                          isWholePageProgress = false;
                          isCartLoading = false;
                        });
                        ToastManager.show(
                          context: context,
                          message: state.error,
                          type: ToastType.error,
                        );
                      } else if (state is CreateOrderProgress) {
                        setState(() {
                          isWholePageProgress = true;
                        });
                      }
                    },
                  ),
                  BlocListener<PaymentBloc, PaymentState>(
                    listener: (context, state) {
                      if (state is PaymentSuccess) {
                        setState(() {
                          isWholePageProgress = false;
                        });
                        context.read<CartUIBloc>().add(SetWalletLoading(false));
                        _initiatePayment(
                            paymentId: state.transactionId,
                            signature: state.signature,
                            orderId: state.orderId);
                      } else if (state is PaymentFailure) {
                        setState(() {
                          isWholePageProgress = false;
                        });
                        context.read<CartUIBloc>().add(SetWalletLoading(false));
                        ToastManager.show(
                            context: context,
                            message: state.error,
                            type: ToastType.error);
                      } else if (state is PaymentLoading) {
                        setState(() {
                          isWholePageProgress = true;
                        });
                      }
                    },
                  ),
                  BlocListener<UpdateItemQuantityBloc, UpdateItemQuantityState>(
                    listener: (context, state) {
                      if (state is UpdateItemQuantityLoading) {
                        // Do not show full screen loader
                      } else if (state is UpdateItemQuantitySuccess) {
                        context.read<GetUserCartBloc>().add(FetchUserCart(
                              addressId: selectedAddress?.id,
                              rushDelivery:
                                  selectedDeliveryType == DeliveryType.rush,
                              useWallet: _userWantsWallet,
                              promoCode: promoCode,
                              isRefresh: true,
                            ));
                      } else if (state is UpdateItemQuantityFailed) {
                        ToastManager.show(
                            context: context,
                            message: state.error,
                            type: ToastType.error);
                        // Refresh cart to revert local optimistic update
                        context.read<GetUserCartBloc>().add(FetchUserCart(
                              addressId: selectedAddress?.id,
                              rushDelivery:
                                  selectedDeliveryType == DeliveryType.rush,
                              useWallet: _userWantsWallet,
                              promoCode: promoCode,
                              isRefresh: true,
                            ));
                      }
                    },
                  ),
                  BlocListener<PromoCodeBloc, PromoCodeState>(
                    listener: (context, state) {
                      if (state is PromoCodeRemoving ||
                          state is PromoCodeApplying ||
                          state is PromoCodeLoading) {
                        setState(() {
                          isCartLoading = true;
                        });
                      } else if (state is PromoCodeFailed) {
                        setState(() {
                          isCartLoading = false;
                        });
                        ToastManager.show(
                            context: context,
                            message: AppLocalizations.of(context)!
                                .promoCodeAppliedOnYourCart);
                      } else if (state is PromoCodeSelected) {
                        setState(() {
                          promoCode = state.promoCode;
                          isCartLoading = false;
                        });
                        if (state.promoCode.isNotEmpty) {
                          ToastManager.show(
                              context: context,
                              message: AppLocalizations.of(context)!
                                  .promoCodeAppliedOnYourCart);
                        }
                      } else if (state is PromoCodeRemoved) {
                        setState(() {
                          promoCode = state.promoCode;
                          isCartLoading = false;
                        });
                      }
                    },
                  ),
                  BlocListener<UserWalletBloc, UserWalletState>(
                    listener: (context, state) {
                      if (state is UserWalletLoaded &&
                          state.userWallet.isNotEmpty) {
                        setState(() {
                          walletBalance = double.tryParse(
                                  state.userWallet.first.balance ?? '0.0') ??
                              0.0;
                        });
                      }
                    },
                  ),
                  BlocListener<ValidatePromoCodeBloc, ValidatePromoCodeState>(
                    listener: (context, state) {
                      if (state is ValidatePromoCodeLoaded) {
                        final validatedCode = context
                            .read<ValidatePromoCodeBloc>()
                            .selectedPromoCode;
                        setState(() {
                          promoCode = validatedCode;
                          _promoController.text = validatedCode;
                          isCartLoading = true;
                        });
                        _refreshCart();
                        ToastManager.show(
                          context: context,
                          message: AppLocalizations.of(context)!
                              .promoCodeAppliedOnYourCart,
                          type: ToastType.success,
                        );
                      } else if (state is ValidatePromoCodeFailed) {
                        ToastManager.show(
                          context: context,
                          message: state.error,
                          type: ToastType.error,
                        );
                      }
                    },
                  ),
                ],
                // FIX: Single BlocBuilder — no more nested BlocBuilder for the same bloc.
                // All rendering uses the `stateData` field, which is always up-to-date
                // because it is set inside setState() in _calculateTotals / the listener.
                child: _buildCartBody(context, l10n),
              ),
              bottomNavigationBar: _buildBottomNav(context),
            ),
            if (isWholePageProgress) WholePageProgress(),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // CART BODY — reads only from local state fields, never from bloc directly
  // ---------------------------------------------------------------------------
  Widget _buildCartBody(BuildContext context, AppLocalizations? l10n) {
    return CustomRefreshIndicator(
      onRefresh: () async {
        context.read<GetUserCartBloc>().add(RefreshUserCart(
              addressId: selectedAddress?.id,
              rushDelivery: selectedDeliveryType == DeliveryType.rush,
              useWallet: _userWantsWallet,
              promoCode: promoCode,
            ));
        context.read<SettingsBloc>().add(FetchSettingsData(context: context));
        context
            .read<GetAddressListBloc>()
            .add(FetchUserAddressList(deliveryZoneId: deliveryZoneId));
        context.read<UserWalletBloc>().add(FetchUserWallet());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: _buildCartContent(context, l10n),
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, AppLocalizations? l10n) {
    // Clearing spinner
    if (isClearingCart) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 50.h),
            const CustomCircularProgressIndicator(),
            SizedBox(height: 10.h),
            Text(
              AppLocalizations.of(context)!.clearingYourCart,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Empty / still syncing — never flash empty UI before API responds
    if (isCartLoading) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: const Center(
          child: CustomCircularProgressIndicator(),
        ),
      );
    }

    // if (stateData.isEmpty ||
    //     stateData.first.data?.items == null ||
    //     stateData.first.data!.items!.isEmpty) {                   ha purn bloc change kela aahe if////} paryant
    //   return _buildEmptyCartState();
    // }

    // final localCartState = context.read<CartBloc>().state;

    // if (stateData.isEmpty ||
    //     stateData.first.data?.items == null ||
    //     stateData.first.data!.items!.isEmpty) {
    //   debugPrint("❌ SERVER CART EMPTY");

    //   // if (localCartState is CartLoaded && localCartState.items.isNotEmpty) {
    //   //   debugPrint("🛒 LOCAL CART HAS ITEMS => ${localCartState.items.length}");

    //   //   setState(() {
    //   //     isCartLoading = true;
    //   //   });

    //   //   Future.microtask(() {
    //   //     context.read<GetUserCartBloc>().add(
    //   //           FetchUserCart(
    //   //             addressId: selectedAddress?.id,
    //   //             rushDelivery: selectedDeliveryType == DeliveryType.rush,
    //   //             useWallet: _userWantsWallet,
    //   //             promoCode: promoCode,
    //   //           ),
    //   //         );
    //   //   });

    //   //   return SizedBox(
    //   //     height: MediaQuery.of(context).size.height * 0.7,
    //   //     child: const Center(
    //   //       child: CustomCircularProgressIndicator(),
    //   //     ),
    //   //   );
    //   // }
    //   if (localCartState is CartLoaded && localCartState.items.isNotEmpty) {
    //     debugPrint("🛒 LOCAL CART HAS ITEMS => ${localCartState.items.length}");

    //     if (!hasRetriedFetch) {
    //       hasRetriedFetch = true;

    //       WidgetsBinding.instance.addPostFrameCallback((_) {
    //         if (!mounted) return;

    //         context.read<GetUserCartBloc>().add(
    //               FetchUserCart(
    //                 addressId: selectedAddress?.id,
    //                 rushDelivery: selectedDeliveryType == DeliveryType.rush,
    //                 useWallet: _userWantsWallet,
    //                 promoCode: promoCode,
    //               ),
    //             );
    //       });
    //     }

    //     return SizedBox(
    //       height: MediaQuery.of(context).size.height * 0.7,
    //       child: const Center(
    //         child: CustomCircularProgressIndicator(),
    //       ),
    //     );
    //   }

    //   return _buildEmptyCartState();
    // }
    // if (stateData.isEmpty ||
    //     stateData.first.data?.items == null ||
    //     stateData.first.data!.items!.isEmpty) {
    //   debugPrint("❌ CART DATA EMPTY");

    //   return SizedBox(
    //     height: MediaQuery.of(context).size.height * 0.7,
    //     child: const Center(
    //       child: CustomCircularProgressIndicator(),
    //     ),
    //   );
    // }
    final localCartState = context.read<CartBloc>().state;

    if (stateData.isEmpty ||
        stateData.first.data == null ||
        stateData.first.data!.items == null ||
        stateData.first.data!.items!.isEmpty) {
      debugPrint("❌ CART EMPTY");

      if (localCartState is CartLoaded && localCartState.items.isNotEmpty) {
        debugPrint(
            "🛒 LOCAL CART HAS ITEMS => ${localCartState.items.length}. Waiting for sync...");

        if (!hasRetriedFetch) {
          hasRetriedFetch = true;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            // Delay allows background sync to complete before fetching
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (!mounted) return;
              context.read<GetUserCartBloc>().add(
                    FetchUserCart(
                      addressId: selectedAddress?.id,
                      rushDelivery: selectedDeliveryType == DeliveryType.rush,
                      useWallet: _userWantsWallet,
                      promoCode: promoCode,
                      isRefresh: true,
                    ),
                  );
            });
          });
        }

        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: const Center(
            child: CustomCircularProgressIndicator(),
          ),
        );
      }

      return _buildEmptyCartState();
    }

    if (stateData.first.data?.items == null ||
        stateData.first.data!.items!.isEmpty) {
      return _buildEmptyCartState();
    }
    // --- Cart has items — build the full content from local stateData ---
    final cartData = stateData;
    final billSummaryData = cartData.first.data!.paymentSummary;

    // Snapshot computed values for this frame (already stored in state fields)
    final finalWalletAmountUsed = walletAmountUsedValue;
    final finalGrandTotal = totalAmount;
    final calculatedItemsTotalVal = calculatedItemsTotal;
    final originalItemsTotalVal = originalItemsTotal;
    final itemSavingsVal = itemSavings;
    final currentDeliveryChargeVal = currentDeliveryCharge;
    final effectiveWalletBalance = walletBalance > 0
        ? walletBalance
        : (billSummaryData?.walletBalance?.toDouble() ?? 0.0);

    return Column(
      children: [
        RemovedItemsWidget(
          removedItems: cartData.first.data?.removedItems ?? [],
        ),
        CartWidget(
          items: cartData.first.data!.items!,
          deliveryTime: cartData
              .first.data!.paymentSummary!.estimatedDeliveryTime
              .toString(),
          onQuantityChanged: _handleQuantityChanged,
          onRemoveItem: _handleRemoveItem,
          onAddMoreItems: _handleAddMoreItems,
          backgroundColor: Theme.of(context).colorScheme.surface,
          quantityButtonColor: AppTheme.primaryColor,
          priceColor: Colors.black,
          originalPriceColor: Colors.grey[500],
          totalItem: cartData.first.data!.totalQuantity,
          addressId: selectedAddress?.id,
          rushDelivery: selectedDeliveryType == DeliveryType.rush,
          useWallet: _userWantsWallet,
          promoCode: promoCode,
        ),
        SizedBox(height: 9.h),
        // You-might-also-like
        BlocBuilder<SimilarProductBloc, SimilarProductState>(
          builder: (context, similarState) {
            if (similarState is SimilarProductLoaded) {
              final cartStoreIds = <int>{};
              for (var cartModel in cartData) {
                if (cartModel.data?.items != null) {
                  for (var item in cartModel.data!.items!) {
                    if (item.storeId != null) cartStoreIds.add(item.storeId!);
                    if (item.store?.id != null)
                      cartStoreIds.add(item.store!.id!);
                  }
                }
              }

              final filteredProducts = cartStoreIds.isNotEmpty
                  ? similarState.similarProduct.where((product) {
                      if (product.variants.isEmpty) return false;
                      final sid = product.variants.first.storeId;
                      return cartStoreIds.contains(sid);
                    }).toList()
                  : <ProductData>[];

              if (filteredProducts.isEmpty) return const SizedBox.shrink();

              return YouMightAlsoLikeProductWidget(
                productData: filteredProducts,
                addressId: selectedAddress?.id,
                rushDelivery: selectedDeliveryType == DeliveryType.rush,
                useWallet: _userWantsWallet,
                promoCode: promoCode,
                isFromCartPage: true,
              );
            } else if (similarState is SimilarProductLoading) {
              return productListShimmer(3);
            }
            return const SizedBox.shrink();
          },
        ),
        SizedBox(height: 9.h),
        DeliveryTypeWidget(
          selectedDeliveryType: selectedDeliveryType,
          rushDeliveryCharge: rushCharge,
          regularDeliveryCharge: 0.0,
          isRushDeliveryDisabled:
              billSummaryData?.isRushDeliveryAvailable == false,
          onDeliveryTypeChanged: (DeliveryType type) {
            setState(() {
              selectedDeliveryType = type;
            });
            _updateCartWithDeliveryType(type);
          },
        ),
        if (selectedDeliveryType != DeliveryType.rush) ...[
          SizedBox(height: 9.h),
          DeliveryTimeSlotWidget(
            timeSlots: stateData.first.data?.timeSlots ??
                stateData.first.data?.deliveryZone?.timeSlots,
            initialSelectedSlot: selectedTimeSlot,
            onSlotSelected: (slot) {
              setState(() {
                selectedTimeSlot = slot;
              });
            },
          ),
        ],
        OrderNoteWidget(
          onNoteChanged: (note) {
            setState(() {
              orderNote = note;
            });
          },
          isEnabled: !isCartLoading,
        ),
        BlocBuilder<CartUIBloc, CartUIState>(
          builder: (context, uiState) {
            final walletAllowed = Global.userData != null;

            if (!walletAllowed && _userWantsWallet) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _userWantsWallet = false;
                  });
                  _refreshCart();
                }
              });
            }

            if (!walletAllowed) return const SizedBox.shrink();

            return Column(
              children: [
                SizedBox(height: 9.h),
                WalletUsageWidget(
                  isWalletEnabled: effectiveUseWallet,
                  isLoading: isCartLoading || uiState.isWalletLoading,
                  walletAmountUsed: finalWalletAmountUsed,
                  remainingBalance:
                      effectiveWalletBalance - finalWalletAmountUsed,
                  onWalletToggle: !uiState.isWalletLoading && !isCartLoading
                      ? (bool value) {
                          setState(() {
                            _userWantsWallet = value;
                            isBillDetailsLoading = true;
                          });
                          _refreshCart();
                        }
                      : (value) {},
                ),
              ],
            );
          },
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: MinimumOrderProgressBar(
              currentTotal: itemsTotal, isBottomAttached: false),
        ),
        offerAndCouponButton(),
        SizedBox(height: 12.h),
        Stack(
          children: [
            BillSummaryWidget(
              itemsOriginalPrice: originalItemsTotalVal > calculatedItemsTotalVal
                  ? originalItemsTotalVal
                  : -1,
              itemsDiscountedPrice: calculatedItemsTotalVal,
              itemsSavings: itemSavingsVal > 0 ? itemSavingsVal : 0,
              deliveryChargeOriginal: currentDeliveryChargeVal,
              handlingCharge: billSummaryData?.handlingCharges?.toDouble() ?? 0,
              grandTotal: finalGrandTotal,
              totalSavings: itemSavingsVal > 0 ? itemSavingsVal : 0,
              perStoreDropOffFees:
                  billSummaryData?.perStoreDropOffFee?.toDouble() ?? 0.0,
              promoCode: billSummaryData?.promoCode,
              promoDiscount:
                  double.tryParse(billSummaryData?.promoDiscount ?? '0') ?? 0,
              promoError: billSummaryData?.promoError,
              removeCoupon: () {
                setState(() {
                  isCartLoading = true;
                  promoCode = '';
                });
                context.read<PromoCodeBloc>().add(RemovePromoCode());
                context.read<GetUserCartBloc>().add(FetchUserCart(
                      addressId: selectedAddress?.id,
                      rushDelivery: selectedDeliveryType == DeliveryType.rush,
                      useWallet: _userWantsWallet,
                      promoCode: promoCode ?? '',
                    ));
              },
              promoMode: billSummaryData?.promoApplied?.promoMode ?? '',
              discountAmount: billSummaryData?.promoApplied?.discountAmount ?? '',
              isRushDelivery: billSummaryData?.isRushDelivery,
              walletAmountUsed: finalWalletAmountUsed,
            ),
            if (isBillDetailsLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: const Center(
                    child: CustomCircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM NAV — reads from local state, no bloc rebuild needed
  // ---------------------------------------------------------------------------
  Widget _buildBottomNav(BuildContext context) {
    if (itemsTotal <= 0) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selectedAddress != null)
          DeliveryAddressWidget(
            selectedAddress: selectedAddress,
            onTap: _showAddressSelectionBottomSheet,
          ),
        _buildCheckoutSection(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS (unchanged logic, just grouped)
  // ---------------------------------------------------------------------------

  List<CartItems> _getProductsMissingRequiredAttachment(
    BuildContext context,
    List<CartItems> cartItems,
  ) {
    final attachmentState = context.read<AttachmentBloc>().state;
    final attachmentsMap = attachmentState is AttachmentLoaded
        ? attachmentState.attachments
        : <int, CartItemAttachment?>{};

    return cartItems.where((item) {
      if (item.product?.isAttachmentRequired != true) return false;
      final attachment = attachmentsMap[item.productId ?? -1];
      return attachment == null;
    }).toList();
  }

  Future<bool> _showClearCartConfirmDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.clearAllItems,
          textAlign: TextAlign.center,
        ),
        content: Text(
          AppLocalizations.of(context)!.allItemsWillBeRemovedCannotBeUndone,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.no ?? 'No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n?.yesClear ?? 'Yes, clear',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _updateCartWithDeliveryType(DeliveryType type) {
    context.read<GetUserCartBloc>().add(FetchUserCart(
          addressId: selectedAddress?.id,
          rushDelivery: type == DeliveryType.rush,
          useWallet: _userWantsWallet,
          promoCode: promoCode ?? '',
        ));
  }

  Widget offerAndCouponButton() {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(TablerIcons.rosette_discount_filled,
                      color: const Color(0xFF149400), size: 20.r),
                  SizedBox(width: 8.w),
                  Text(
                    l10n?.promoCodeCoupons ?? 'Promo Code & Coupons',
                    style:
                        TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  final result = await GoRouter.of(context)
                      .push(AppRoutes.promoCode, extra: {
                    'cartAmount': stateData
                            .first.data?.paymentSummary?.itemsTotal
                            ?.toDouble() ??
                        0.0,
                    'deliveryCharges': stateData
                            .first.data?.paymentSummary?.totalDeliveryCharges
                            ?.toDouble() ??
                        0.0,
                  });
                  if (result != null &&
                      result is String &&
                      result.isNotEmpty &&
                      mounted) {
                    setState(() {
                      promoCode = result;
                      _promoController.text = result;
                    });
                    _refreshCart();
                  }
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (promoCode != null && promoCode!.isNotEmpty)
            Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFF149400).withOpacity(0.06),
                borderRadius: BorderRadius.circular(8.r),
                border:
                    Border.all(color: const Color(0xFF149400).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(TablerIcons.circle_check_filled,
                      color: const Color(0xFF149400), size: 18.r),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '${promoCode?.toUpperCase()} Applied!',
                      style: TextStyle(
                        color: const Color(0xFF149400),
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isCartLoading = true;
                        promoCode = '';
                        _promoController.clear();
                      });
                      context.read<PromoCodeBloc>().add(RemovePromoCode());
                      _refreshCart();
                    },
                    child: Text(
                      'Remove',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: TextField(
                      controller: _promoController,
                      decoration: InputDecoration(
                        hintText: l10n?.promoCode ?? 'Enter Promo Code',
                        border: InputBorder.none,
                        hintStyle:
                            TextStyle(fontSize: 13.sp, color: Colors.grey),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                SizedBox(
                  height: 40.h,
                  child: BlocBuilder<ValidatePromoCodeBloc,
                      ValidatePromoCodeState>(
                    builder: (context, state) {
                      final isLoading = state is ValidatePromoCodeLoading;
                      return ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                final code = _promoController.text.trim();
                                if (code.isNotEmpty) {
                                  context
                                      .read<ValidatePromoCodeBloc>()
                                      .selectedPromoCode = code;
                                  context
                                      .read<ValidatePromoCodeBloc>()
                                      .add(ValidatePromoCodeRequest(
                                        promoCode: code,
                                        cartAmount: stateData.first.data
                                                ?.paymentSummary?.itemsTotal
                                                ?.toInt() ??
                                            0,
                                        deliveryCharges: stateData
                                                .first
                                                .data
                                                ?.paymentSummary
                                                ?.totalDeliveryCharges
                                                ?.toInt() ??
                                            0,
                                      ));
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r)),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text('Apply',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.sp)),
                      );
                    },
                  ),
                ),
              ],
            ),
          BlocBuilder<PromoCodeBloc, PromoCodeState>(
            builder: (context, state) {
              if (state is PromoCodeLoaded && state.promoCodeData.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),
                    Text(
                      'Suggested Offers',
                      style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      height: 40.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: math.min(state.promoCodeData.length, 5),
                        itemBuilder: (context, index) {
                          final coupon = state.promoCodeData[index];
                          final isApplied = coupon.code != null &&
                              promoCode != null &&
                              coupon.code!.toLowerCase() ==
                                  promoCode!.toLowerCase();
                          return Padding(
                            padding: EdgeInsets.only(right: 8.w),
                            child: ActionChip(
                              avatar: isApplied
                                  ? Icon(Icons.check_circle,
                                      size: 14.r,
                                      color: const Color(0xFF149400))
                                  : null,
                              label: Text(
                                coupon.code ?? '',
                                style: TextStyle(
                                  color: isApplied
                                      ? const Color(0xFF149400)
                                      : AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                ),
                              ),
                              backgroundColor: isApplied
                                  ? const Color(0xFF149400).withOpacity(0.1)
                                  : AppTheme.primaryColor.withOpacity(0.1),
                              side: BorderSide(
                                color: isApplied
                                    ? const Color(0xFF149400).withOpacity(0.3)
                                    : AppTheme.primaryColor.withOpacity(0.3),
                              ),
                              onPressed: isApplied
                                  ? null
                                  : () {
                                      _promoController.text = coupon.code ?? '';
                                      context
                                              .read<ValidatePromoCodeBloc>()
                                              .selectedPromoCode =
                                          coupon.code ?? '';
                                      context
                                          .read<ValidatePromoCodeBloc>()
                                          .add(ValidatePromoCodeRequest(
                                            promoCode: coupon.code ?? '',
                                            cartAmount: stateData.first.data
                                                    ?.paymentSummary?.itemsTotal
                                                    ?.toInt() ??
                                                0,
                                            deliveryCharges: stateData
                                                    .first
                                                    .data
                                                    ?.paymentSummary
                                                    ?.totalDeliveryCharges
                                                    ?.toInt() ??
                                                0,
                                          ));
                                    },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  void _handleQuantityChanged(String itemId, int newQuantity) {
    setState(() {
      isBillDetailsLoading = true;
    });
    context.read<UpdateItemQuantityBloc>().add(UpdateItemQuantityRequest(
          cartItemId: int.parse(itemId),
          quantity: newQuantity,
        ));
  }

  void _handleRemoveItem(String itemId) {
    setState(() {
      isBillDetailsLoading = true;
    });
    context
        .read<RemoveItemFromCartBloc>()
        .add(RemoveItemFromCartRequest(cartItemId: int.parse(itemId)));
  }

  void _handleAddMoreItems() {
    context.go(AppRoutes.home);
  }

  void _showAddressSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => AddressSelectionBottomSheet(
        selectedAddress: selectedAddress,
        deliveryZoneId: deliveryZoneId,
        onAddressSelected: (address) {
          if (address.id != selectedAddress?.id) {
            setState(() {
              selectedAddress = address;
              selectedDeliveryType = DeliveryType.regular;
              isCartLoading = true;
            });
            HiveSelectedAddressHelper.setSelectedAddress(address);
            context.read<GetUserCartBloc>().add(FetchUserCart(
                  addressId: address.id,
                  useWallet: _userWantsWallet,
                  rushDelivery: selectedDeliveryType == DeliveryType.rush,
                  promoCode: promoCode,
                ));
          }
        },
      ),
    );
  }

  void _navigateToPaymentOptions() async {
    final l10n = AppLocalizations.of(context);
    if (selectedAddress == null) {
      ToastManager.show(
          context: context,
          message: l10n?.pleaseSelectADeliveryAddressFirst ??
              'Please select a delivery address first',
          type: ToastType.error);
      return;
    }

    final paymentMethodType = await context.push(
      AppRoutes.paymentOptions,
      extra: {'totalAmount': totalAmount},
    );

    if (paymentMethodType != null && paymentMethodType is PaymentMethodType) {
      final paymentMethod =
          PaymentConfig.getPaymentMethodByType(paymentMethodType);
      if (paymentMethod != null) {
        setState(() {
          selectedPaymentMethod = paymentMethod.id;
          selectedPaymentMethodType = paymentMethod.type;
        });
      }
    }
  }

  void _processOrder(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (totalAmount <= 0) {
      _initiatePayment();
      return;
    }
    if (selectedPaymentMethod == null) {
      ToastManager.show(
          context: context,
          message: l10n?.selectPaymentMethod ??
              'Please select a payment method first',
          type: ToastType.error);
      return;
    }
    if (selectedPaymentMethod != 'cod' &&
        selectedPaymentMethodType != PaymentMethodType.flutterwave) {
      context.read<PaymentBloc>().add(
            InitiatePaymentEvent(
              paymentMethodType: selectedPaymentMethodType!,
              amount: totalAmount,
              additionalData: {
                'userId': Global.userData?.userId.toString() ?? '',
                'customerName': Global.userData?.name.toString() ?? '',
                'email': Global.userData?.email.toString() ?? '',
                'phone': Global.userData?.mobile.toString() ?? '',
                'deliveryAddress': formatAddressFromModel(selectedAddress!),
              },
              addMoneyToWallet: false,
              context: context,
            ),
          );
    } else {
      _initiatePayment();
    }
  }

  void _initiatePayment({
    String? paymentId,
    String? signature,
    String? orderId,
  }) {
    final attachmentState = context.read<AttachmentBloc>().state;
    final attachments = attachmentState is AttachmentLoaded
        ? attachmentState.attachments
        : <int, CartItemAttachment?>{};

    final l10n = AppLocalizations.of(context);
    if (totalAmount <= 0) {
      context.read<CreateOrderBloc>().add(CreateOrderRequest(
            paymentType: 'wallet',
            addressId: selectedAddress!.id!,
            rushDelivery: selectedDeliveryType == DeliveryType.rush,
            promoCode: promoCode,
            useWallet: _userWantsWallet,
            paymentDetails: selectedPaymentMethod == 'razorpay'
                ? {
                    'razorpay_order_id': orderId ?? '',
                    'razorpay_signature': signature ?? '',
                    'transaction_id': paymentId ?? '',
                  }
                : {'transaction_id': paymentId ?? ''},
            usedAmountValue: walletAmountUsedValue,
            orderNote: orderNote,
            attachments: attachments,
            deliveryTimeSlotId: selectedDeliveryType == DeliveryType.rush
                ? 'Quick Delivery'
                : selectedTimeSlot?.id?.toString(),
          ));
      return;
    }
    if (selectedPaymentMethod == null && selectedPaymentMethodType == null) {
      ToastManager.show(
        context: context,
        message:
            l10n?.paymentMethodNotSelected ?? 'Payment method not selected',
        type: ToastType.error,
      );
      return;
    }
    context.read<CreateOrderBloc>().add(CreateOrderRequest(
          paymentType: selectedPaymentMethod!,
          addressId: selectedAddress!.id!,
          rushDelivery: selectedDeliveryType == DeliveryType.rush,
          promoCode: promoCode,
          useWallet: _userWantsWallet,
          paymentDetails: selectedPaymentMethod == 'razorpay'
              ? {
                  'razorpay_order_id': orderId ?? '',
                  'razorpay_signature': signature ?? '',
                  'transaction_id': paymentId ?? '',
                }
              : {'transaction_id': paymentId ?? ''},
          usedAmountValue: walletAmountUsedValue,
          orderNote: orderNote,
          attachments: attachments,
          deliveryTimeSlotId: selectedDeliveryType == DeliveryType.rush
              ? 'Quick Delivery'
              : selectedTimeSlot?.id?.toString(),
        ));
  }

  Widget _buildCheckoutSection() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 20),
      child: selectedAddress != null
          ? Row(
              children: [
                if (totalAmount > 0.0)
                  if (selectedPaymentMethod != null &&
                      selectedPaymentMethodType != null) ...[
                    InkWell(
                      onTap: _navigateToPaymentOptions,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: PaymentConfig.getPaymentMethodWidget(
                                    selectedPaymentMethod!,
                                    size: 24),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                (l10n?.payUsing ?? 'Pay Using').toUpperCase(),
                                style: TextStyle(
                                    fontSize: 10.sp, letterSpacing: 1.1),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Icon(Icons.arrow_drop_up),
                            ],
                          ),
                          Text(
                            PaymentConfig.getPaymentMethodName(
                                selectedPaymentMethod!),
                            style: TextStyle(
                                fontSize: 12.sp, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                const SizedBox(height: 5),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: CustomButton(
                      isDisabled: itemsTotal < AppConstant.minimumOrderValue,
                      onPressed: isCartLoading
                          ? () {}
                          : () {
                              final storeIds = stateData.first.data!.items!
                                  .map((item) => item.storeId)
                                  .where((id) => id != null)
                                  .cast<int>()
                                  .toSet();

                              final cartValidationError =
                                  CartValidation.validateCartForCheckout(
                                context: context,
                                cartTotal: itemsTotal,
                                uniqueItemsCount:
                                    stateData.first.data!.itemsCount!,
                                storeIds: storeIds,
                              );

                              if (cartValidationError != null) {
                                ToastManager.show(
                                  context: context,
                                  message: cartValidationError,
                                );
                                return;
                              }

                              final missingAttachmentProducts =
                                  _getProductsMissingRequiredAttachment(
                                context,
                                stateData.first.data!.items ?? [],
                              );

                              if (missingAttachmentProducts.isNotEmpty) {
                                final productNames = missingAttachmentProducts
                                    .map(
                                        (p) => "• ${p.product?.name ?? 'Item'}")
                                    .join("\n");
                                ToastManager.show(
                                  context: context,
                                  message:
                                      "Attachment required for:\n$productNames\nPlease add the required file(s).",
                                  type: ToastType.error,
                                  duration: const Duration(seconds: 5),
                                );
                                return;
                              }

                              if (totalAmount <= 0 ||
                                  selectedPaymentMethod != null) {
                                _processOrder(context);
                              } else {
                                _navigateToPaymentOptions();
                              }
                            },
                      child: isCartLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(),
                            )
                          : Text(
                              (selectedPaymentMethod != null ||
                                      totalAmount <= 0.0)
                                  ? (l10n?.placeOrder ?? 'Place Order')
                                  : (l10n?.selectPaymentMethod ??
                                      'Select payment method'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            )
          : SizedBox(
              height: 50,
              width: double.infinity,
              child: CustomButton(
                onPressed: _showAddressSelectionBottomSheet,
                child: Text(
                  AppLocalizations.of(context)!.chooseAddressForDelivery,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyCartState() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              l10n?.yourCartIsEmpty ?? 'Your cart is empty',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.looksLikeYouHaventAddedAnythingYet ??
                  'Looks like you haven\'t added anything yet',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 44,
              child: CustomButton(
                onPressed: () => GoRouter.of(context).pop(),
                child: Text(
                  l10n?.browseProducts ?? 'Browse products',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddAddress() async {
    await GoRouter.of(context).push(
      AppRoutes.locationPicker,
      extra: {
        'isFromAddressPage': true,
        'isEdit': false,
        'isFromCartPage': true,
        'deliveryZoneId': deliveryZoneId,
      },
    );
  }
}
