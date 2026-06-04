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

  final VoidCallback? onSeeAllTap;

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
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    if (featureSectionData == null ||
        featureSectionData!.products == null ||
        featureSectionData!.products!.isEmpty) {
      return const SizedBox.shrink();
    }

    final section = featureSectionData!;

    return Container(
      padding: EdgeInsets.only(top: 18.h, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    featureSectionTitle ?? section.title ?? "",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (onSeeAllTap != null)
                  InkWell(
                    onTap: onSeeAllTap,
                    borderRadius: BorderRadius.circular(8.r),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      child: Text(
                        "See All",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15.sp,
                        ),
                      ),
                    ),
                  )
                else
                  Icon(Icons.arrow_forward_ios,
                      size: 16.sp, color: Colors.grey),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            height: 245.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: section.products!.length,
              itemBuilder: (context, index) {
                final product = section.products![index];
                if (product.variants.isEmpty) {
                  return const SizedBox.shrink();
                }
                final variant = product.variants.first;
                return Container(
                  width: 175.w,
                  margin: EdgeInsets.only(right: 20.w),
                  child: CustomProductCard(
                    heroTagPrefix: '${featureSectionSlug}_',
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
                    quickDeliveryAvailable: product.quickDeliveryAvailable,
                    onAddToCart: (qty) {
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
                                originalPrice: variant.price.toDouble(),
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
                    wishlistItemId:
                        (product.favorite?.any((f) => f.wishlistId == 1) ??
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
                    tieredPricing: null, // Removed from UI as requested
                    indicator: product.indicator,
                    mrp: variant.mrp.toString(),
                    mrpStatus: variant.mrpStatus,
                    pricePerUnit: variant.pricePerUnit.toString(),
                    measurementUnit: variant.measurementUnit,
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
