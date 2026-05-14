import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import '../../model/tiered_pricing.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:grofery_user/config/constant.dart';
import 'package:grofery_user/config/theme.dart';
import 'package:grofery_user/screens/product_detail_page/view/product_detail_page.dart';
import 'package:grofery_user/services/auth_guard.dart';
import 'package:grofery_user/utils/widgets/animated_button.dart';
import 'package:grofery_user/utils/widgets/custom_delivery_time_widget.dart';
import 'package:grofery_user/utils/widgets/price_utils.dart';
import 'package:grofery_user/utils/widgets/custom_image_container.dart';
import '../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../bloc/user_cart_bloc/user_cart_state.dart';
import '../../config/global.dart';
import '../../model/user_cart_model/user_cart.dart';
import '../../screens/wishlist_page/widgets/wishlist_bottom_sheet.dart';
import '../../screens/wishlist_page/bloc/get_user_wishlist_bloc/get_user_wishlist_bloc.dart';
import '../../screens/wishlist_page/bloc/get_user_wishlist_bloc/get_user_wishlist_state.dart';
import '../../screens/wishlist_page/bloc/wishlist_product_bloc/wishlist_product_bloc.dart';
import 'package:flutter/services.dart';
import '../../services/user_cart/cart_validation.dart';
import 'custom_toast.dart';

class CustomProductCard extends StatelessWidget {
  final int productId;
  final String productImage;
  final String productName;
  final String productSlug;
  final String productPrice;
  final List<String> productTags;
  final String specialPrice;
  final String estimatedDeliveryTime;
  final String? assetImage;
  final double ratings;
  final int ratingCount;
  final Function(int quantity) onAddToCart;
  final bool isStoreOpen;
  final bool isWishListed;
  final int productVariantId;
  final int storeId;
  final int wishlistItemId;
  final int totalStocks;
  final String imageFit;
  final bool showWishlist;
  final int? variantCount;
  final VoidCallback? onVariantSelectorRequested;
  final int quantityStepSize;
  final int minQty;
  final int totalAllowedQuantity;
  final String? indicator;
  final bool useHorizontalLayout;
  final bool isSimilarProductLayout;
  final List<TieredPricing>? tieredPricing;
  final String? mrp;
  final int? mrpStatus;
  final bool quickDeliveryAvailable;

  const CustomProductCard({
    super.key,
    required this.productId,
    required this.productImage,
    required this.productName,
    required this.productSlug,
    required this.productPrice,
    required this.productTags,
    this.assetImage,
    required this.specialPrice,
    required this.estimatedDeliveryTime,
    required this.ratings,
    required this.ratingCount,
    required this.onAddToCart,
    required this.isStoreOpen,
    required this.isWishListed,
    required this.productVariantId,
    required this.storeId,
    required this.wishlistItemId,
    required this.totalStocks,
    required this.imageFit,
    this.showWishlist = true,
    this.variantCount,
    this.onVariantSelectorRequested,
    required this.quantityStepSize,
    required this.minQty,
    required this.totalAllowedQuantity,
    this.indicator,
    this.useHorizontalLayout = false,
    this.isSimilarProductLayout = false,
    this.tieredPricing,
    this.mrp,
    this.mrpStatus,
    this.quickDeliveryAvailable = false,
  });

  BoxFit get boxFit {
    return BoxFit.contain;
  }

  @override
  Widget build(BuildContext context) {
    final String heroTag =
        'card-image-$productId-$productSlug-${identityHashCode(this)}';

    if (isSimilarProductLayout) {
      return _buildSimilarProductLayout(context, heroTag);
    }

    if (useHorizontalLayout) {
      return _buildHorizontalLayout(context, heroTag);
    }
    return OpenContainer(
      clipBehavior: Clip.antiAlias,
      transitionDuration: const Duration(milliseconds: 500),
      transitionType: ContainerTransitionType.fade,
      closedElevation: 0,
      openElevation: 0,
      closedShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      openShape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      closedColor: Colors.transparent,
      openColor: Colors.transparent,
      tappable: false,
      useRootNavigator: true,
      closedBuilder: (context, openContainer) {
        return GestureDetector(
          onTap: openContainer,
          child: Opacity(
            opacity: totalStocks <= 0 ? 0.5 : 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5.r),
                border: Border.all(color: Colors.grey.shade200, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      productImageWidget(
                          productImage: productImage,
                          discountPercentage:
                              PriceUtils.calculateDiscountPercentage(
                                      double.tryParse(productPrice) ?? 0.0,
                                      double.tryParse(specialPrice) ?? 0.0)
                                  .toString(),
                          heroTag: heroTag,
                          context: context),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 8.h),
                          child: BlocBuilder<CartBloc, CartState>(
                              builder: (context, state) {
                            final cartItem = _getCartItem(state);
                            final int currentQty = cartItem?.quantity ?? 0;
                            final double effectivePrice =
                                _calculateEffectivePrice(
                                    currentQty > 0 ? currentQty : 1);
                            final double original =
                                double.tryParse(productPrice) ?? 0.0;
                            final displayQty = currentQty > 0
                                ? currentQty
                                : (minQty > 0 ? minQty : 1);
                            final totalPrice = effectivePrice * displayQty;
                            final totalOriginalPrice = original * displayQty;

                            return SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  productNameWidget(
                                      productName: productName,
                                      context: context),
                                  SizedBox(height: 2.h),
                                  productPriceWidget(
                                      price: (mrpStatus == 1 &&
                                              (double.tryParse(mrp ?? '0') ??
                                                      0) >
                                                  0)
                                          ? totalOriginalPrice.toString()
                                          : '',
                                      specialPrice: totalPrice.toString(),
                                      locale: AppConstant.defaultLocalCurrency,
                                      context: context),
                                  if (minQty > 1)
                                    Padding(
                                      padding: EdgeInsets.only(top: 2.h),
                                      child: Text(
                                        "at ₹${formatPrice(effectivePrice)}/pc",
                                        style: TextStyle(
                                          fontSize: 9.sp,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  SizedBox(height: 4.h),
                                  _buildQuickDeliveryBadge(
                                      quickDeliveryAvailable),
                                  SizedBox(height: 3.h),
                                  _buildBulkTierPricing(context, currentQty),
                                  SizedBox(height: 3.h),
                                  ratingWidget(context),
                                  if (minQty > 1) ...[
                                    SizedBox(height: 3.h),
                                    Text(
                                      "Minimum Order: $minQty ${minQty > 1 ? 'pcs' : 'pc'}",
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: AppTheme.fontFamily,
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 4.h),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      openBuilder: (context, closeContainer) {
        return ProductDetailPage(
          productSlug: productSlug,
          initialData: ProductInitialData(
            title: productName,
            mainImage: productImage,
            heroTag: heroTag,
          ),
          closeContainer: closeContainer,
        );
      },
    );
  }

  Widget _buildQuickDeliveryBadge(bool available) {
    if (!available) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          TablerIcons.bolt,
          size: 14.sp,
          color: const Color(0xFFFFB300), // Bright yellow/orange
        ),
        SizedBox(width: 2.w),
        Text(
          'Quick',
          style: TextStyle(
            fontSize: 12.sp,
            color: const Color(0xFFFFB300),
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ],
    );
  }

  Widget productImageWidget({
    required String productImage,
    required String discountPercentage,
    required BuildContext context,
    String? heroTag,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          Container(
            margin: EdgeInsetsDirectional.only(end: 8.w, bottom: 4.h),
            width: double.infinity,
            height: 140.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            ),
            padding: const EdgeInsets.all(4.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: productImage.isNotEmpty
                  ? heroTag != null
                      ? Hero(
                          tag: heroTag,
                          child: CustomImageContainer(
                              imagePath: productImage, fit: boxFit),
                        )
                      : CustomImageContainer(
                          imagePath: productImage, fit: boxFit)
                  : _buildAssetImageOrPlaceholder(),
            ),
          ),
          if (discountPercentage.isNotEmpty && discountPercentage != '0')
            PositionedDirectional(
              top: 0,
              start: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.discountCardColor,
                  borderRadius: BorderRadiusDirectional.only(
                    topStart: Radius.circular(8.r),
                    bottomEnd: Radius.circular(4.r),
                  ),
                ),
                child: Text(
                  '$discountPercentage% OFF',
                  style: TextStyle(
                    fontSize: isTablet(context) ? 12 : 8.sp,
                    color: Colors.white,
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          if (indicator != null &&
              (indicator == 'veg' || indicator == 'non_veg'))
            PositionedDirectional(
              bottom: 12.h,
              start: 5.w,
              child: Container(
                width: 14.sp,
                height: 14.sp,
                padding: EdgeInsets.all(2.sp),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: indicator == 'veg' ? Colors.green : Colors.red,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: indicator == 'veg' ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          PositionedDirectional(
            bottom: 8.h,
            end: 3.w,
            child: BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                final cartItem = _getCartItem(state);
                final isInCart = cartItem != null;

                final Set<int> currentStoreIds = {};
                int currentUniqueItems = 0;

                if (state is CartLoaded) {
                  currentStoreIds.addAll(
                    state.items
                        .map((item) => int.tryParse(item.vendorId))
                        .where((id) => id != null)
                        .cast<int>(),
                  );
                  currentUniqueItems = state.items.length;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  width: isInCart ? 95.w : 65.w,
                  height: 30.h,
                  decoration: BoxDecoration(
                    color: isInCart ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: AppTheme.primaryColor,
                      width: 1.5.w,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.85, end: 1.0)
                              .animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: isInCart
                        ? _QuantityStepperInner(
                            key: const ValueKey('stepper_inner'),
                            quantity: cartItem.quantity,
                            currentLocalQty: cartItem.quantity,
                            stepSize: quantityStepSize,
                            isStoreOpen: isStoreOpen,
                            stock: totalStocks,
                            minQty: minQty,
                            totalAllowedQuantity: totalAllowedQuantity,
                            onIncrement: () async {
                              await HapticFeedback.lightImpact();
                              if (variantCount != null &&
                                  variantCount! > 1 &&
                                  onVariantSelectorRequested != null) {
                                onVariantSelectorRequested!();
                              } else {
                                if (context.mounted) {
                                  final error =
                                      CartValidation.validateProductAddToCart(
                                    context: context,
                                    requestedQuantity:
                                        cartItem.quantity + quantityStepSize,
                                    minQty: minQty,
                                    maxQty: totalAllowedQuantity,
                                    stock: totalStocks,
                                    isStoreOpen: isStoreOpen,
                                  );

                                  if (error != null) {
                                    ToastManager.show(
                                        context: context,
                                        message: error,
                                        type: ToastType.error);
                                    return;
                                  } else {
                                    context.read<CartBloc>().add(
                                          UpdateCartQty(
                                              cartKey: cartItem.cartKey,
                                              quantity: cartItem.quantity +
                                                  quantityStepSize,
                                              cartItemId:
                                                  cartItem.serverCartItemId,
                                              context: context),
                                        );
                                  }
                                }
                              }
                            },
                            onDecrement: () async {
                              await HapticFeedback.lightImpact();
                              if (variantCount != null &&
                                  variantCount! > 1 &&
                                  onVariantSelectorRequested != null) {
                                onVariantSelectorRequested!();
                              } else {
                                if (cartItem.quantity > quantityStepSize) {
                                  if (context.mounted) {
                                    context.read<CartBloc>().add(
                                          UpdateCartQty(
                                              cartKey: cartItem.cartKey,
                                              quantity: cartItem.quantity -
                                                  quantityStepSize,
                                              cartItemId:
                                                  cartItem.serverCartItemId,
                                              context: context),
                                        );
                                  }
                                } else {
                                  if (context.mounted) {
                                    context.read<CartBloc>().add(
                                          RemoveFromCart(
                                              cartKey: cartItem.cartKey,
                                              context: context),
                                        );
                                  }
                                }
                              }
                            },
                          )
                        : _AddButtonInner(
                            key: const ValueKey('add_button_inner'),
                            currentLocalQty: cartItem?.quantity ?? 0,
                            stepSize: quantityStepSize,
                            isStoreOpen: isStoreOpen,
                            stock: totalStocks,
                            minQty: minQty,
                            totalAllowedQuantity: totalAllowedQuantity,
                            onTap: totalStocks > 0
                                ? () async {
                                    await HapticFeedback.lightImpact();

                                    if (context.mounted) {
                                      // Toggle logic: If already in cart (rare case where button is still visible), remove it
                                      if (isInCart) {
                                        context.read<CartBloc>().add(
                                              RemoveFromCart(
                                                  cartKey: cartItem.cartKey,
                                                  context: context),
                                            );
                                        return;
                                      }

                                      final error = CartValidation
                                          .validateProductAddToCart(
                                        context: context,
                                        requestedQuantity: quantityStepSize,
                                        minQty: minQty,
                                        maxQty: totalAllowedQuantity,
                                        stock: totalStocks,
                                        isStoreOpen: isStoreOpen,
                                      );

                                      final cartError = CartValidation
                                          .validateBeforeAddToCart(
                                        context: context,
                                        currentUniqueItemsCount:
                                            currentUniqueItems,
                                        isNewItem: !isInCart,
                                        currentStoreIdsInCart: currentStoreIds,
                                        thisProductStoreId: storeId,
                                      );

                                      if (error != null || cartError != null) {
                                        ToastManager.show(
                                            context: context,
                                            message: cartError ?? error!,
                                            type: ToastType.error);
                                        return;
                                      } else {
                                        onAddToCart(quantityStepSize);
                                      }
                                    }
                                  }
                                : null,
                            opacity: totalStocks > 0 ? 1.0 : 0.5,
                          ),
                  ),
                );
              },
            ),
          ),
          PositionedDirectional(
            top: 6.h,
            end: 6.w,
            child: _buildWishlistButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistButton(BuildContext context,
      {double size = 30, double iconSize = 18}) {
    if (!showWishlist) return const SizedBox.shrink();

    return BlocBuilder<UserWishlistBloc, UserWishlistState>(
      builder: (context, wishlistState) {
        final bloc = context.read<UserWishlistBloc>();
        final isWishListedFromBloc =
            bloc.isProductWishlisted(productId, productVariantId, storeId);
        final currentWishlistItemId =
            bloc.getWishlistItemId(productId, productVariantId, storeId);
        final hasBlocData =
            bloc.hasProductData(productId, productVariantId, storeId);

        final finalIsWishListed =
            hasBlocData ? isWishListedFromBloc : isWishListed;
        final finalWishlistItemId = currentWishlistItemId ?? wishlistItemId;

        return AnimatedButton(
          onTap: () async {
            if (Global.userData != null) {
              final wishlistBloc = context.read<UserWishlistBloc>();

              // CASE 1: Product is already wishlisted -> Remove it directly
              if (finalIsWishListed) {
                if (finalWishlistItemId != null && finalWishlistItemId != 0) {
                  wishlistBloc.add(RemoveItemFromWishlist(
                    itemId: finalWishlistItemId ?? 0,
                    productId: productId,
                    productVariantId: productVariantId,
                    storeId: storeId,
                  ));

                  // Sync with local wishlist product listing if needed
                  context
                      .read<WishlistProductBloc>()
                      .add(RemoveProductLocally(itemId: finalWishlistItemId));
                } else {
                  // We know it's wishlisted but don't have the ID, BLoC will try to find it
                  wishlistBloc.add(RemoveItemFromWishlist(
                    itemId: 0,
                    productId: productId,
                    productVariantId: productVariantId,
                    storeId: storeId,
                  ));
                }
                return;
              }

              // CASE 2: Product not wishlisted -> Try to add directly if any wishlist exists
              if (!finalIsWishListed) {
                if (wishlistState is UserWishlistLoaded &&
                    wishlistState.wishlistData.isNotEmpty) {
                  final wishlist = wishlistState.wishlistData.first;
                  wishlistBloc.add(
                    AddItemInWishlist(
                      wishlistTitle: wishlist.title ?? '',
                      productId: productId,
                      productVariantId: productVariantId,
                      storeId: storeId,
                    ),
                  );
                } else {
                  // CASE 3: No wishlist yet -> Create default one and add product
                  final userName = Global.userData?.name ?? 'My Wishlist';
                  wishlistBloc.add(
                    CreateNewWishlist(
                      title: userName,
                      productId: productId,
                      productVariantId: productVariantId,
                      storeId: storeId,
                    ),
                  );
                }
                return;
              }
            } else {
              await AuthGuard.ensureLoggedIn(context);
            }
          },
          child: Container(
            height: size.r,
            width: size.r,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              finalIsWishListed ? Icons.favorite : Icons.favorite_border,
              color: finalIsWishListed ? Colors.red : Colors.black87,
              size: iconSize.r,
            ),
          ),
        );
      },
    );
  }

  UserCart? _getCartItem(CartState state) {
    List<UserCart> items = [];
    if (state is CartLoaded) {
      items = state.items;
    } else if (state is CartLoading) {
      items = state.items;
    } else {
      return null;
    }

    try {
      return items.firstWhere(
        (item) =>
            (int.tryParse(item.productId) ?? 0) == productId &&
            (int.tryParse(item.variantId) ?? 0) == productVariantId &&
            (int.tryParse(item.vendorId) ?? 0) == storeId,
      );
    } catch (_) {
      return null;
    }
  }

  double _calculateEffectivePrice(int quantity) {
    final double regPrice = double.tryParse(productPrice) ?? 0.0;
    final double spPrice = double.tryParse(specialPrice) ?? 0.0;
    final double basePrice = spPrice > 0 ? spPrice : regPrice;

    if (tieredPricing == null || tieredPricing!.isEmpty) {
      return basePrice;
    }

    TieredPricing? applicableTier;
    for (var tier in tieredPricing!) {
      if (quantity >= tier.minQty) {
        applicableTier = tier;
      } else {
        break;
      }
    }

    return applicableTier != null
        ? (applicableTier.price / applicableTier.minQty)
        : basePrice;
  }

  Widget _buildBulkTierPricing(BuildContext context, int currentQty) {
    if (tieredPricing == null || tieredPricing!.isEmpty)
      return const SizedBox.shrink();
    return _buildInternalBulkOffers(context, currentQty);
  }

  Widget _buildInternalBulkOffers(BuildContext context, int currentQty) {
    if (tieredPricing == null || tieredPricing!.isEmpty)
      return const SizedBox.shrink();

    return _TieredPricingExpandableList(
      tieredPricing: tieredPricing!,
      currentQty: currentQty,
      onAddToCart: onAddToCart,
      getCartItem: (state) => _getCartItem(state),
      basePrice: double.tryParse(productPrice) ?? 0.0,
      mrp: double.tryParse(mrp ?? '') ?? 0.0,
      packSize: 1,
    );
  }

  String formatPrice(double price) {
    if (price == price.toInt()) {
      return price.toInt().toString();
    }
    return price.toStringAsFixed(2);
  }

  Widget _buildSimilarProductLayout(BuildContext context, String heroTag) {
    String discountPercentage = PriceUtils.calculateDiscountPercentage(
            double.tryParse(productPrice) ?? 0.0,
            double.tryParse(specialPrice) ?? 0.0)
        .toString();

    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
            color: Colors.grey.shade200.withValues(alpha: 0.5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Navigation area (Image + Info)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                GoRouter.of(context).push(
                  AppRoutes.productDetailPage,
                  extra: {
                    'productSlug': productSlug,
                    'initialData': ProductInitialData(
                      title: productName,
                      mainImage: productImage,
                      heroTag: heroTag,
                    ),
                  },
                );
              },
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Image on top
                  SizedBox(
                    height: 100.h,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12.r),
                          alignment: Alignment.center,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: productImage.isNotEmpty
                                ? CustomImageContainer(
                                    imagePath: productImage,
                                    fit: BoxFit.contain,
                                  )
                                : _buildAssetImageOrPlaceholder(),
                          ),
                        ),
                        PositionedDirectional(
                          top: 6.h,
                          end: 6.w,
                          child: _buildWishlistButton(context),
                        ),
                        if (indicator != null &&
                            (indicator == 'veg' || indicator == 'non_veg'))
                          PositionedDirectional(
                            bottom: 6.h,
                            start: 12.w,
                            child: Container(
                              width: 14.w,
                              height: 14.w,
                              padding: EdgeInsets.all(2.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: indicator == 'veg'
                                      ? Colors.green
                                      : Colors.red,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: indicator == 'veg'
                                      ? Colors.green
                                      : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 2. Info below
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuickDeliveryBadge(quickDeliveryAvailable),
                        SizedBox(height: 3.h),
                        Text(
                          productName,
                          style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                              height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 3.h),
                        // Price Row
                        BlocBuilder<CartBloc, CartState>(
                            builder: (context, state) {
                          final cartItem = _getCartItem(state);
                          final int currentQty = cartItem?.quantity ?? 0;
                          final double effectivePrice =
                              _calculateEffectivePrice(currentQty > 0
                                  ? currentQty
                                  : (minQty > 0 ? minQty : 1));
                          final double original =
                              double.tryParse(productPrice) ?? 0.0;
                          final displayQty = currentQty > 0
                              ? currentQty
                              : (minQty > 0 ? minQty : 1);
                          final totalPrice = effectivePrice * displayQty;
                          final totalOriginalPrice = original * displayQty;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    "₹${formatPrice(totalPrice)}",
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  if (mrpStatus == 1) ...[
                                    Builder(builder: (context) {
                                      final double parsedMrp =
                                          double.tryParse(mrp ?? '') ?? 0.0;
                                      final double originalPrice = parsedMrp;
                                      if (originalPrice <= 0)
                                        return const SizedBox.shrink();
                                      return Text(
                                        "₹${formatPrice(totalOriginalPrice)}",
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey.shade400,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    }),
                                  ],
                                ],
                              ),
                              if (minQty > 1)
                                Padding(
                                  padding: EdgeInsets.only(top: 1.h),
                                  child: Text(
                                    "at ₹${formatPrice(effectivePrice)}/pc",
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              SizedBox(height: 3.h),
                              ratingWidget(context),
                              if (minQty > 1) ...[
                                SizedBox(height: 3.h),
                                Text(
                                  "Minimum Order: $minQty ${minQty > 1 ? 'pcs' : 'pc'}",
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: AppTheme.fontFamily,
                                  ),
                                ),
                              ],
                              if (tieredPricing != null &&
                                  tieredPricing!.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: 4.h),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        tieredPricing!.take(1).map((tier) {
                                      final double tierUnitPrice =
                                          tier.price / tier.minQty;
                                      return Text(
                                        "₹${formatPrice(tierUnitPrice)}/pc for ${tier.minQty}+",
                                        style: TextStyle(
                                            fontSize: 10.sp,
                                            color: const Color(0xFF2E6FF2),
                                            fontWeight: FontWeight.w700,
                                            height: 1.1),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Action area (Independent of navigation InkWell)
          _buildSimilarAddButton(context),
        ],
      ),
    );
  }

  Widget _buildSimilarAddButton(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final cartItem = _getCartItem(state);
        final isInCart = cartItem != null;

        return Padding(
          padding: EdgeInsets.fromLTRB(8.r, 4.r, 8.r, 8.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: 34.h,
            decoration: BoxDecoration(
              color:
                  isInCart ? const Color(0xFFE54A50) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: const Color(0xFFE54A50),
                width: 1.0,
              ),
            ),
            child: isInCart
                ? _QuantityStepperInner(
                    key: const ValueKey('stepper_inner_sim'),
                    quantity: cartItem.quantity,
                    currentLocalQty: cartItem.quantity,
                    stepSize: quantityStepSize,
                    isStoreOpen: isStoreOpen,
                    stock: totalStocks,
                    minQty: minQty,
                    totalAllowedQuantity: totalAllowedQuantity,
                    onIncrement: () => _handleIncrement(context, cartItem),
                    onDecrement: () => _handleDecrement(context, cartItem),
                  )
                : Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleAddToCart(context, state),
                      borderRadius: BorderRadius.circular(10.r),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            "ADD",
                            style: TextStyle(
                              color: const Color(0xFFE54A50),
                              fontWeight: FontWeight.w800,
                              fontSize: 13.sp,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Positioned(
                            right: 12.w,
                            child: Icon(
                              TablerIcons.plus,
                              color: const Color(0xFFE54A50),
                              size: 16.sp,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildHorizontalLayout(BuildContext context, String heroTag) {
    String discountPercentage = PriceUtils.calculateDiscountPercentage(
            double.tryParse(productPrice) ?? 0.0,
            double.tryParse(specialPrice) ?? 0.0)
        .toString();

    return Container(
      margin: EdgeInsets.only(bottom: 4.h, left: 0, right: 2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            GoRouter.of(context).push(
              AppRoutes.productDetailPage,
              extra: {
                'productSlug': productSlug,
                'initialData': ProductInitialData(
                  title: productName,
                  mainImage: productImage,
                  heroTag: heroTag,
                ),
              },
            );
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Half
                  Padding(
                    padding: EdgeInsets.only(
                        left: 8.w, right: 10.w, top: 8.h, bottom: 4.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildQuickDeliveryBadge(quickDeliveryAvailable),
                              SizedBox(height: 6.h),
                              Text(
                                productName,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  height: 1.3,
                                ),
                              ),
                              if (productTags.isNotEmpty &&
                                  productTags.first != "[]") ...[
                                SizedBox(height: 6.h),
                                Text(
                                  productTags.first,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(2.w),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E8A37),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.star_rounded,
                                        color: Colors.white, size: 10.sp),
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    ratings.toString(),
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    "($ratingCount)",
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              if (minQty > 1) ...[
                                SizedBox(height: 6.h),
                                Text(
                                  "Minimum Order: $minQty ${minQty > 1 ? 'pcs' : 'pc'}",
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: AppTheme.fontFamily,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        // Right Side Image
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 105.w,
                              height: 105.w,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Hero(
                                  tag: heroTag,
                                  child: CustomImageContainer(
                                    imagePath: productImage,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            // Wishlist heart
                            PositionedDirectional(
                              bottom: 4.w,
                              end: 4.w,
                              child: _buildWishlistButton(context,
                                  size: 24, iconSize: 14),
                            ),
                            // Veg indicator on image
                            if (indicator != null &&
                                (indicator == 'veg' || indicator == 'non_veg'))
                              PositionedDirectional(
                                bottom: -3.w,
                                start: -3.w,
                                child: Container(
                                  width: 14.w,
                                  height: 14.w,
                                  padding: EdgeInsets.all(2.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: indicator == 'veg'
                                          ? Colors.green
                                          : Colors.red,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: indicator == 'veg'
                                          ? Colors.green
                                          : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
                  // Bottom Half Pricing & Action
                  Padding(
                    padding:
                        EdgeInsets.only(left: 8.w, right: 10.w, top: 6.h, bottom: 4.h),
                    child: BlocBuilder<CartBloc, CartState>(
                      builder: (context, state) {
                        final cartItem = _getCartItem(state);
                        final int currentQty = cartItem?.quantity ?? 0;
                        final double effectivePrice = _calculateEffectivePrice(
                            currentQty > 0 ? currentQty : 1);
                        final double parsedMrp =
                            double.tryParse(mrp ?? '') ?? 0.0;
                        final double original = parsedMrp;
                        final displayQty = currentQty > 0
                            ? currentQty
                            : (minQty > 0 ? minQty : 1);
                        final totalPrice = effectivePrice * displayQty;
                        final totalOriginalPrice = original * displayQty;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          "₹${formatPrice(totalPrice)}",
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(width: 4.w),
                                        if (mrpStatus == 1 &&
                                            totalOriginalPrice > 0)
                                          Text(
                                            "₹${formatPrice(totalOriginalPrice)}",
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: Colors.grey.shade500,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      "at ₹${formatPrice(effectivePrice)}/pc",
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                _buildAddToCartButton(context),
                              ],
                            ),
                            _buildBulkTierPricing(context, currentQty),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              // 18% OFF Badge Top Right
              if (discountPercentage.isNotEmpty && discountPercentage != '0')
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3771E0),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16.r),
                        bottomLeft: Radius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      '$discountPercentage% OFF',
                      style: TextStyle(
                        fontSize: 8.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddToCartButton(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final cartItem = _getCartItem(state);
        final isInCart = cartItem != null;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 95.w,
          height: 34.h,
          decoration: BoxDecoration(
            color: isInCart ? const Color(0xFFE54A50) : Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color:
                  isInCart ? const Color(0xFFE54A50) : const Color(0xFFEAB9BC),
              width: 1.2,
            ),
          ),
          child: isInCart
              ? _QuantityStepperInner(
                  key: const ValueKey('stepper_inner'),
                  quantity: cartItem.quantity,
                  currentLocalQty: cartItem.quantity,
                  stepSize: quantityStepSize,
                  isStoreOpen: isStoreOpen,
                  stock: totalStocks,
                  minQty: minQty,
                  totalAllowedQuantity: totalAllowedQuantity,
                  onIncrement: () {
                    _handleIncrement(context, cartItem);
                  },
                  onDecrement: () {
                    _handleDecrement(context, cartItem);
                  },
                )
              : _AddButtonInner(
                  key: const ValueKey('add_button_inner'),
                  currentLocalQty: 0,
                  stepSize: quantityStepSize,
                  isStoreOpen: isStoreOpen,
                  stock: totalStocks,
                  minQty: minQty,
                  totalAllowedQuantity: totalAllowedQuantity,
                  onTap: () {
                    _handleAddToCart(context, state);
                  },
                  opacity: totalStocks > 0 ? 1.0 : 0.5,
                ),
        );
      },
    );
  }

  void _handleAddToCart(BuildContext context, CartState state) async {
    debugPrint(
        'CustomProductCard: _handleAddToCart called for Product ID: $productId, Variant ID: $productVariantId');
    final Set<int> currentStoreIds = {};
    int currentUniqueItems = 0;
    bool isInCart = false;

    if (state is CartLoaded) {
      currentStoreIds.addAll(
        state.items
            .map((item) => int.tryParse(item.vendorId))
            .where((id) => id != null)
            .cast<int>(),
      );
      currentUniqueItems = state.items.length;
      isInCart = state.items.any((item) =>
          int.tryParse(item.productId) == productId &&
          int.tryParse(item.variantId) == productVariantId &&
          int.tryParse(item.vendorId) == storeId);
    }

    await HapticFeedback.lightImpact();

    if (context.mounted) {
      if (isInCart && state is CartLoaded) {
        // Toggle logic: Remove if already in cart
        final cartItem = state.items.firstWhere(
          (item) =>
              (int.tryParse(item.productId) ?? 0) == productId &&
              (int.tryParse(item.variantId) ?? 0) == productVariantId &&
              (int.tryParse(item.vendorId) ?? 0) == storeId,
          orElse: () => state.items.first,
        );
        context
            .read<CartBloc>()
            .add(RemoveFromCart(cartKey: cartItem.cartKey, context: context));
        return;
      }

      final error = CartValidation.validateProductAddToCart(
        context: context,
        requestedQuantity: minQty > 0 ? minQty : 1,
        minQty: minQty,
        maxQty: totalAllowedQuantity,
        stock: totalStocks,
        isStoreOpen: isStoreOpen,
      );

      final cartError = CartValidation.validateBeforeAddToCart(
        context: context,
        currentUniqueItemsCount: currentUniqueItems,
        isNewItem: !isInCart,
        currentStoreIdsInCart: currentStoreIds,
        thisProductStoreId: storeId,
      );

      if (error != null || cartError != null) {
        ToastManager.show(
            context: context,
            message: cartError ?? error!,
            type: ToastType.error);
        return;
      } else {
        onAddToCart(minQty > 0 ? minQty : 1);
      }
    }
  }

  void _handleIncrement(BuildContext context, UserCart cartItem) async {
    await HapticFeedback.lightImpact();
    if (variantCount != null &&
        variantCount! > 1 &&
        onVariantSelectorRequested != null) {
      onVariantSelectorRequested!();
    } else {
      if (context.mounted) {
        final error = CartValidation.validateProductAddToCart(
          context: context,
          requestedQuantity: cartItem.quantity + 1,
          minQty: minQty,
          maxQty: totalAllowedQuantity,
          stock: totalStocks,
          isStoreOpen: isStoreOpen,
        );

        if (error != null) {
          ToastManager.show(
              context: context, message: error, type: ToastType.error);
          return;
        } else {
          context.read<CartBloc>().add(
                UpdateCartQty(
                    cartKey: cartItem.cartKey,
                    quantity: cartItem.quantity + 1,
                    cartItemId: cartItem.serverCartItemId,
                    context: context),
              );
        }
      }
    }
  }

  void _handleDecrement(BuildContext context, UserCart cartItem) async {
    await HapticFeedback.lightImpact();
    if (variantCount != null &&
        variantCount! > 1 &&
        onVariantSelectorRequested != null) {
      onVariantSelectorRequested!();
    } else {
      if (cartItem.quantity > minQty) {
        if (context.mounted) {
          context.read<CartBloc>().add(
                UpdateCartQty(
                    cartKey: cartItem.cartKey,
                    quantity: cartItem.quantity - 1,
                    cartItemId: cartItem.serverCartItemId,
                    context: context),
              );
        }
      } else {
        if (context.mounted) {
          context.read<CartBloc>().add(
                RemoveFromCart(cartKey: cartItem.cartKey, context: context),
              );
        }
      }
    }
  }

  Widget _buildAssetImageOrPlaceholder() {
    if (assetImage != null && assetImage!.isNotEmpty) {
      return CustomImageContainer(
        imagePath: assetImage!,
        fit: BoxFit.cover,
      );
    }
    return Container(
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey[400],
        size: 24.sp,
      ),
    );
  }

  Widget productTagsWidget({required List<String> tags}) {
    final List<String> validTags = tags.where((tag) => tag.isNotEmpty).toList();
    if (validTags.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        double availableWidth = constraints.maxWidth;
        double tagSpacing = 4.w;

        return Wrap(
          spacing: tagSpacing,
          runSpacing: 2.h,
          children: validTags.take(2).map((tag) {
            return Container(
              constraints: BoxConstraints(
                maxWidth: (availableWidth - tagSpacing) / 2,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 8.sp,
                  fontFamily: AppTheme.fontFamily,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget productNameWidget(
      {required String productName, required BuildContext context}) {
    return SizedBox(
      height: 32.h, // Fixed height for 2 lines to ensure alignment
      child: Text(
        productName,
        style: TextStyle(
          fontSize: isTablet(context) ? 20 : 10.5.sp,
          height: 1.2,
          fontFamily: AppTheme.fontFamily,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget productPriceWidget({
    required String price,
    required String specialPrice,
    required String locale,
    required BuildContext context,
  }) {
    final double regular = double.tryParse(price) ?? 0.0;
    final double special = double.tryParse(specialPrice) ?? 0.0;

    final bool hasDiscount = price.isNotEmpty && regular > special;
    final String displayPrice = specialPrice;

    final formattedDisplay = formatPrice(double.tryParse(displayPrice) ?? 0.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${AppConstant.currency}$formattedDisplay',
          style: TextStyle(
            fontSize: isTablet(context) ? 20 : 14.sp,
            fontWeight: FontWeight.bold,
            fontFamily: AppTheme.fontFamily,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 8),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              '${AppConstant.currency}${formatPrice(regular)}',
              style: TextStyle(
                fontSize: isTablet(context) ? 16 : 11.sp,
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.grey,
                decorationThickness: 2,
                color: Colors.grey,
                fontFamily: AppTheme.fontFamily,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget ratingWidget(BuildContext context) {
    return Row(
      children: [
        RatingBar.builder(
          initialRating: ratings,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemSize: 11.h,
          itemBuilder: (context, _) => Icon(
            AppTheme.ratingStarIconFilled,
            color: AppTheme.ratingStarColor,
          ),
          unratedColor: Colors.grey[350],
          onRatingUpdate: (rating) {},
          ignoreGestures: true,
        ),
        SizedBox(
          width: 5.w,
        ),
        Expanded(
          child: Text(
            '($ratingCount)',
            style: TextStyle(
              fontSize: isTablet(context) ? 18 : 8.sp,
              fontFamily: AppTheme.fontFamily,
              color: Colors.grey,
            ),
          ),
        )
      ],
    );
  }
}

class _AddButtonInner extends StatelessWidget {
  final VoidCallback? onTap;
  final double opacity;
  final int currentLocalQty;
  final int stepSize;
  final int minQty;
  final int totalAllowedQuantity;
  final int stock;
  final bool isStoreOpen;

  const _AddButtonInner({
    required Key key,
    required this.onTap,
    required this.opacity,
    required this.currentLocalQty,
    required this.stepSize,
    required this.minQty,
    required this.totalAllowedQuantity,
    required this.stock,
    required this.isStoreOpen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: stock > 0 ? onTap : null,
        borderRadius: BorderRadius.circular(6.r),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          child: Opacity(
            opacity: opacity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "ADD",
                  style: TextStyle(
                    color: const Color(0xFFE54A50),
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  TablerIcons.plus,
                  size: 18.r,
                  color: const Color(0xFFE54A50),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuantityStepperInner extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final int currentLocalQty;
  final int stepSize;
  final int minQty;
  final int totalAllowedQuantity;
  final int stock;
  final bool isStoreOpen;

  const _QuantityStepperInner({
    required Key key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.currentLocalQty,
    required this.stepSize,
    required this.minQty,
    required this.totalAllowedQuantity,
    required this.stock,
    required this.isStoreOpen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: InkWell(
              onTap: onDecrement,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.r),
                bottomLeft: Radius.circular(8.r),
              ),
              child: Container(
                alignment: Alignment.center,
                child: Icon(
                  TablerIcons.minus,
                  size: 18.r,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              quantity.toString(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onIncrement,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(8.r),
                bottomRight: Radius.circular(8.r),
              ),
              child: Container(
                alignment: Alignment.center,
                child: Icon(
                  TablerIcons.plus,
                  size: 18.r,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TieredPricingExpandableList extends StatefulWidget {
  final List<TieredPricing> tieredPricing;
  final int currentQty;
  final Function(int) onAddToCart;
  final UserCart? Function(CartState) getCartItem;
  final double basePrice;
  final double mrp;
  final int packSize;

  const _TieredPricingExpandableList({
    Key? key,
    required this.tieredPricing,
    required this.currentQty,
    required this.onAddToCart,
    required this.getCartItem,
    required this.basePrice,
    required this.mrp,
    required this.packSize,
  }) : super(key: key);

  @override
  _TieredPricingExpandableListState createState() =>
      _TieredPricingExpandableListState();
}

class _TieredPricingExpandableListState
    extends State<_TieredPricingExpandableList> {
  String formatPriceLocally(double price) {
    if (price == price.toInt()) return price.toInt().toString();
    return price.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    TieredPricing? activeTier;
    for (var tier in widget.tieredPricing) {
      if (widget.currentQty >= tier.minQty) {
        if (activeTier == null || tier.minQty > activeTier.minQty) {
          activeTier = tier;
        }
      }
    }

    // Always show all tiers as requested by the user
    final tiersToShow = widget.tieredPricing;

    return Container(
      margin: EdgeInsets.only(top: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FE),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Column(
              children: List.generate(tiersToShow.length, (index) {
                final tier = tiersToShow[index];
                final bool isSelectedTier = activeTier == tier;
                // isExactMatch is used to determine if we should "Toggle Off" or just "Reset to Tier Min"
                final bool isExactMatch = widget.currentQty == tier.minQty;

                // Calculation: (MrpPerUnit * currentQty) - (TierUnitPrice * currentQty)
                final double unitBasePrice = widget.basePrice / widget.packSize;
                final double unitMrp = (widget.mrp > 0 ? widget.mrp : widget.basePrice) / widget.packSize;
                final double tierUnitPrice = tier.price / tier.minQty;

                // Use current quantity if this is the active tier, otherwise use tier min
                final int effectiveQty =
                    isSelectedTier ? widget.currentQty : tier.minQty;
                final double savings =
                    (unitMrp - tierUnitPrice) * effectiveQty;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: isSelectedTier
                        ? const Color(0xFFE7F6EB)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isSelectedTier
                          ? const Color(0xFFB9E4C2)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      final cartBloc = context.read<CartBloc>();
                      final cartState = cartBloc.state;
                      final cartItem = widget.getCartItem(cartState);

                      int targetQty = isExactMatch ? 0 : tier.minQty;
                      HapticFeedback.lightImpact();

                      if (targetQty <= 0) {
                        if (cartItem != null) {
                          cartBloc.add(RemoveFromCart(
                              cartKey: cartItem.cartKey, context: context));
                        }
                        return;
                      }

                      if (cartItem != null) {
                        cartBloc.add(UpdateCartQty(
                          cartKey: cartItem.cartKey,
                          quantity: targetQty,
                          cartItemId: cartItem.serverCartItemId,
                          context: context,
                        ));
                      } else {
                        widget.onAddToCart(targetQty);
                      }
                    },
                    borderRadius: BorderRadius.circular(8.r),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "₹${formatPriceLocally(tierUnitPrice)}/pc for ${tier.minQty} pcs+",
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w800,
                                    color: isSelectedTier
                                        ? const Color(0xFF1D8936)
                                        : const Color(0xFF1E5BB2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (isSelectedTier)
                                Container(
                                  padding: EdgeInsets.all(2.r),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1D8936),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 12.sp,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.w, vertical: 6.h),
                                  decoration: const BoxDecoration(
                                    color: Colors.transparent,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "ADD",
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFE54A50),
                                        ),
                                      ),
                                      SizedBox(width: 2.w),
                                      Icon(
                                        TablerIcons.plus,
                                        size: 16.sp,
                                        color: const Color(0xFFE54A50),
                                      ),
                                    ],
                                  ),
                                ),
                              if (isSelectedTier && savings > 0) ...[
                                SizedBox(height: 2.h),
                                Text(
                                  "Saved ₹${formatPriceLocally(savings)}",
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF1D8936),
                                    fontFamily: AppTheme.fontFamily,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
