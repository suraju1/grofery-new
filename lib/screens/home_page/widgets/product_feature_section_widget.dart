import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grofery_user/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:grofery_user/bloc/user_cart_bloc/user_cart_event.dart';
import 'package:grofery_user/model/user_cart_model/user_cart.dart';
import 'package:grofery_user/model/user_cart_model/cart_sync_action.dart';
import '../../../utils/widgets/custom_product_card.dart';
import '../model/featured_section_product_model.dart';

class ProductFeatureSectionWidget extends StatelessWidget {
  final FeatureSectionData? featureSectionData;
  final String? featureSectionTitle;
  final String? backgroundImage;
  final String? backgroundImageTablet;
  final String featureSectionSlug;
  final String featureSectionStyle;
  final String? backgroundColor;
  final String? backgroundType;

  const ProductFeatureSectionWidget({
    super.key,
    this.featureSectionData,
    this.featureSectionTitle,
    this.backgroundImage,
    this.backgroundImageTablet,
    required this.featureSectionSlug,
    required this.featureSectionStyle,
    this.backgroundColor,
    this.backgroundType,
  });

  @override
  Widget build(BuildContext context) {
    if (featureSectionData == null || featureSectionData!.products == null) {
      return const SizedBox.shrink();
    }

    final section = featureSectionData!;

    return Container(
      padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  featureSectionTitle ?? section.title ?? "",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 280.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: section.products!.length,
              itemBuilder: (context, index) {
                final product = section.products![index];
                return Container(
                  width: 175.w,
                  margin: EdgeInsets.only(right: 12.w),
                  child: CustomProductCard(
                    productId: product.id,
                    productImage: product.mainImage,
                    productName: product.title,
                    productSlug: product.slug,
                    productPrice: product.variants.first.price.toString(),
                    productTags: product.tags,
                    specialPrice:
                        product.variants.first.specialPrice.toString(),
                    estimatedDeliveryTime: product.estimatedDeliveryTime,
                    ratings: product.ratings.toDouble(),
                    ratingCount: product.ratingCount,
                    onAddToCart: (qty) {
                      final variant = product.variants.first;
                      context.read<CartBloc>().add(
                            AddToCart(
                              context: context,
                              item: UserCart(
                                productId: product.id.toString(),
                                variantId: variant.id.toString(),
                                variantName: variant.title,
                                vendorId: variant.storeId.toString(),
                                name: product.title,
                                image: product.mainImage,
                                price: variant.getEffectivePrice(qty),
                                originalPrice:
                                    variant.price.toDouble(),
                                quantity: qty,
                                minQty: product.minimumOrderQuantity,
                                maxQty: product.totalAllowedQuantity,
                                isOutOfStock: variant.stock <= 0,
                                isSynced: false,
                                updatedAt: DateTime.now(),
                                syncAction: CartSyncAction.add,
                                tieredPricing: variant.tieredPricing,
                              ),
                            ),
                          );
                    },
                    isStoreOpen: product.storeStatus?.isOpen ?? true,
                    isWishListed: product.favorite != null &&
                        product.favorite!.any((f) => f.wishlistId == 1),
                    productVariantId: product.variants.first.id,
                    storeId: product.variants.first.storeId,
                    wishlistItemId: (product.favorite?.any(
                                (f) => f.wishlistId == 1) ??
                            false)
                        ? product.favorite!
                                .firstWhere((f) => f.wishlistId == 1)
                                .id ??
                            0
                        : 0,
                    totalStocks: product.variants.first.stock,
                    imageFit: product.imageFit,
                    quantityStepSize: product.quantityStepSize,
                    minQty: product.minimumOrderQuantity,
                    totalAllowedQuantity: product.totalAllowedQuantity,
                    tieredPricing: product.variants.first.tieredPricing,
                    indicator: product.indicator,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
