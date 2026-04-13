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
  final List<TieredPricing>? tieredPricing;

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
    this.tieredPricing,
  });

  BoxFit get boxFit {
    switch (imageFit.toLowerCase()) {
      case 'cover':
        return BoxFit.cover;
      case 'contain':
      default:
        return BoxFit.contain;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String heroTag =
        'card-image-$productId-$productSlug-${identityHashCode(this)}';

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
                borderRadius: BorderRadius.circular(8.r),
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
                                      double.parse(productPrice),
                                      double.parse(specialPrice))
                                  .toString(),
                          heroTag: heroTag,
                          context: context),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.h),
                        child: BlocBuilder<CartBloc, CartState>(
                            builder: (context, state) {
                          final cartItem = _getCartItem(state);
                          final int currentQty = cartItem?.quantity ?? 0;
                          final double effectivePrice =
                              _calculateEffectivePrice(
                                  currentQty > 0 ? currentQty : 1);
                          final double original =
                              double.tryParse(productPrice) ?? 0.0;
                          final displayQty = currentQty > 0 ? currentQty : 1;
                          final totalPrice = effectivePrice * displayQty;
                          final totalOriginalPrice = original * displayQty;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              productNameWidget(
                                  productName: productName, context: context),
                              SizedBox(height: 2.h),
                              productPriceWidget(
                                  price: totalOriginalPrice.toString(),
                                  specialPrice: totalPrice.toString(),
                                  locale: AppConstant.defaultLocalCurrency,
                                  context: context),
                              SizedBox(height: 3.h),
                              _buildBulkTierPricing(context, currentQty),
                              SizedBox(height: 3.h),
                              ratingWidget(context),
                              SizedBox(height: 4.h),
                              DeliveryTimeWidget(time: estimatedDeliveryTime),
                            ],
                          );
                        }),
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
            height: 100.h,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(8.r),
            ),
            padding: boxFit == BoxFit.contain
                ? const EdgeInsets.all(10.0)
                : EdgeInsets.zero,
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
          if (showWishlist)
            PositionedDirectional(
              top: 3.h,
              end: 12.w,
              child: BlocBuilder<UserWishlistBloc, UserWishlistState>(
                builder: (context, wishlistState) {
                  final bloc = context.read<UserWishlistBloc>();
                  final isWishListedFromBloc = bloc.isProductWishlisted(
                      productId, productVariantId, storeId);
                  final currentWishlistItemId = bloc.getWishlistItemId(
                      productId, productVariantId, storeId);
                  final hasBlocData =
                      bloc.hasProductData(productId, productVariantId, storeId);

                  final finalIsWishListed =
                      hasBlocData ? isWishListedFromBloc : isWishListed;
                  final finalWishlistItemId =
                      currentWishlistItemId ?? wishlistItemId;

                  if (!finalIsWishListed) return const SizedBox.shrink();

                  return AnimatedButton(
                    onTap: () async {
                      if (Global.userData != null) {
                        context
                            .read<UserWishlistBloc>()
                            .add(GetUserWishlistRequest());
                        await showModalBottomSheet<String>(
                          context: context,
                          useSafeArea: true,
                          isScrollControlled: true,
                          useRootNavigator: true,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          constraints: BoxConstraints(maxHeight: 500.h),
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (_) => AddToWishlistSheetBody(
                            productId: productId,
                            productVariantId: productVariantId,
                            storeId: storeId,
                            wishlistItemId: finalWishlistItemId,
                          ),
                        );
                      } else {
                        await AuthGuard.ensureLoggedIn(context);
                      }
                    },
                    child: Container(
                      height: 28.r,
                      width: 28.r,
                      decoration: BoxDecoration(
                        color: isDarkMode(context)
                            ? Colors.black.withValues(alpha: 0.9)
                            : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 15.r,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
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

  String formatPrice(double price) {
    if (price == price.toInt()) {
      return price.toInt().toString();
    }
    return price.toStringAsFixed(2);
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
    );
  }

  Widget _buildHorizontalLayout(BuildContext context, String heroTag) {
    String discountPercentage = PriceUtils.calculateDiscountPercentage(
            double.parse(productPrice), double.parse(specialPrice))
        .toString();

    return Container(
      margin: EdgeInsets.only(bottom: 16.h, left: 8.w, right: 8.w),
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
                        left: 12.w, right: 12.w, top: 16.h, bottom: 12.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.timer_outlined,
                                      color: const Color(0xFF0B7B69),
                                      size: 14.sp),
                                  SizedBox(width: 4.w),
                                  Flexible(
                                    child: Text(
                                      estimatedDeliveryTime.isNotEmpty
                                          ? "Prep time: $estimatedDeliveryTime"
                                          : "Prep time: 10 mins",
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0B7B69),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                productName,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (productTags.isNotEmpty) ...[
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
                              SizedBox(height: 10.h),
                              Row(
                                children: [
                                  Container(
                                    width: 4.w,
                                    height: 4.w,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE54A50),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Flexible(
                                    child: Text(
                                      "Preparation guide",
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: const Color(0xFFE54A50),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        // Right Side Image
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 80.w,
                              height: 80.w,
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
                            if (showWishlist && isWishListed)
                              PositionedDirectional(
                                top: 4.w,
                                end: 4.w,
                                child: Icon(Icons.favorite,
                                    color: Colors.red, size: 20.sp),
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
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                    child: BlocBuilder<CartBloc, CartState>(
                      builder: (context, state) {
                        final cartItem = _getCartItem(state);
                        final int currentQty = cartItem?.quantity ?? 0;
                        final double effectivePrice = _calculateEffectivePrice(
                            currentQty > 0 ? currentQty : 1);
                        final double original =
                            double.tryParse(productPrice) ?? 0.0;
                        final displayQty = currentQty > 0 ? currentQty : 1;
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
                                        if (totalPrice < totalOriginalPrice)
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
      height: isTablet(context) ? 48 : 35,
      child: Text(
        productName,
        style: TextStyle(
          fontSize: isTablet(context) ? 20 : 11.5.sp,
          height: isTablet(context) ? 1.2 : 1.2,
          fontFamily: AppTheme.fontFamily,
          fontWeight: FontWeight.w500,
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

    final bool hasDiscount = special > 0 && special < regular;

    final String displayPrice = hasDiscount ? specialPrice : price;

    final formattedDisplay = formatPrice(double.parse(displayPrice));

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

  const _TieredPricingExpandableList({
    Key? key,
    required this.tieredPricing,
    required this.currentQty,
    required this.onAddToCart,
    required this.getCartItem,
  }) : super(key: key);

  @override
  _TieredPricingExpandableListState createState() => _TieredPricingExpandableListState();
}

class _TieredPricingExpandableListState extends State<_TieredPricingExpandableList> {
  bool isExpanded = false;

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

    final tiersToShow = isExpanded ? widget.tieredPricing : [activeTier ?? widget.tieredPricing.first];

    return Container(
      margin: EdgeInsets.only(top: 8.h),
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

                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "₹${formatPriceLocally(tier.price / tier.minQty)}/pc for ${tier.minQty} pcs+",
                              style: TextStyle(
                                fontSize: 9.sp, 
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E5BB2),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Material(
                            color: Colors.transparent,
                            child: AnimatedButton(
                              animationType: TapAnimationType.scale,
                              duration: const Duration(milliseconds: 100),
                              scaleAmount: 0.95,
                              onTap: () {
                                final cartBloc = context.read<CartBloc>();
                                final cartState = cartBloc.state;
                                final cartItem = widget.getCartItem(cartState);

                                int targetQty;
                                if (isExactMatch) {
                                  // Perfectly matched: Toggle off to remove
                                  targetQty = 0;
                                } else {
                                  // Not exact: Either jump TO this tier or RESET to its minimum
                                  targetQty = tier.minQty;
                                }

                                HapticFeedback.lightImpact();

                                if (targetQty <= 0) {
                                  if (cartItem != null) {
                                    cartBloc.add(RemoveFromCart(
                                      cartKey: cartItem.cartKey,
                                      context: context,
                                    ));
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
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: isSelectedTier ? const Color(0xFFE54A50) : Colors.white,
                                  borderRadius: BorderRadius.circular(4.r),
                                  border: Border.all(color: const Color(0xFFE54A50), width: 1),
                                ),
                                child: Text(
                                  "Add ${tier.minQty}",
                                  style: TextStyle(
                                    fontSize: 9.sp, 
                                    fontWeight: FontWeight.bold,
                                    color: isSelectedTier ? Colors.white : const Color(0xFFE54A50),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index < tiersToShow.length - 1)
                      Divider(height: 4.h, thickness: 1, color: const Color(0xFFDFEDFD)),
                  ],
                );
              }),
            ),
          ),
          if (widget.tieredPricing.length > 1)
            GestureDetector(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(bottom: 4.h, top: 2.h),
                color: Colors.transparent,
                child: Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.more_horiz,
                  size: 16.sp,
                  color: const Color(0xFF1E5BB2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
