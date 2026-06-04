import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grofery_user/screens/product_detail_page/model/product_detail_model.dart';
import 'package:grofery_user/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:grofery_user/bloc/user_cart_bloc/user_cart_event.dart';
import 'package:grofery_user/model/user_cart_model/user_cart.dart';
import 'package:grofery_user/model/user_cart_model/cart_sync_action.dart';
import '../../../utils/widgets/custom_product_card.dart';
import '../bloc/similar_product_bloc/similar_product_bloc.dart';
import '../widgets/product_detail_shimmer.dart';

class SimilarProductWidget extends StatelessWidget {
  final String? productSlug;
  final List<ProductData>? product;

  const SimilarProductWidget({super.key, this.productSlug, this.product});

  @override
  Widget build(BuildContext context) {
    if (product != null) {
      return _buildProductList(context, product!);
    }
    return BlocBuilder<SimilarProductBloc, SimilarProductState>(
      builder: (context, state) {
        if (state is SimilarProductLoaded) {
          return _buildProductList(context, state.similarProduct);
        } else if (state is SimilarProductLoading) {
          return productListShimmer(3);
        } else if (state is SimilarProductFailure) {
          return const SizedBox.shrink();
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProductList(
      BuildContext context, List<ProductData> similarProducts) {
    if (similarProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Text(
            "Similar Products",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 285.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: similarProducts.length,
            itemBuilder: (context, index) {
              final product = similarProducts[index];
              if (product.variants.isEmpty) return const SizedBox.shrink();

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
                  specialPrice: product.variants.first.specialPrice.toString(),
                  estimatedDeliveryTime: product.estimatedDeliveryTime,
                  ratings: product.ratings.toDouble(),
                  ratingCount: product.ratingCount,
                  quickDeliveryAvailable: product.quickDeliveryAvailable,
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
                  isWishListed:
                      product.favorite != null && product.favorite!.isNotEmpty,
                  productVariantId: product.variants.first.id,
                  storeId: product.variants.first.storeId,
                  wishlistItemId:
                      (product.favorite != null && product.favorite!.isNotEmpty)
                          ? product.favorite!.first.id ?? 0
                          : 0,
                  totalStocks: product.variants.first.stock,
                  imageFit: product.imageFit,
                  quantityStepSize: product.quantityStepSize,
                  minQty: product.minimumOrderQuantity,
                  totalAllowedQuantity: product.totalAllowedQuantity,
                  tieredPricing: product.variants.first.tieredPricing,
                  indicator: product.indicator,
                  isSimilarProductLayout: true,
                  mrp: product.variants.first.mrp.toString(),
                  mrpStatus: product.variants.first.mrpStatus,
                  pricePerUnit:
                      product.variants.first.pricePerUnit.toString(),
                  measurementUnit: product.variants.first.measurementUnit,
                ),
              );
            },
          ),
        ),
        SizedBox(height: 100.h),
      ],
    );
  }
}
