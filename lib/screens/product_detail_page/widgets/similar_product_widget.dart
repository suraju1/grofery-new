import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grofery_user/screens/product_detail_page/model/product_detail_model.dart';
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

  Widget _buildProductList(BuildContext context, List<ProductData> similarProducts) {
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
          height: 300.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: similarProducts.length,
            itemBuilder: (context, index) {
              final product = similarProducts[index];
              return Container(
                width: 160.w,
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
                  onAddToCart: (qty) {},
                  isStoreOpen: product.storeStatus?.isOpen ?? true,
                  isWishListed: product.favorite != null && product.favorite!.isNotEmpty,
                  productVariantId: product.variants.first.id,
                  storeId: product.variants.first.storeId,
                  wishlistItemId: product.favorite?.first.id ?? 0,
                  totalStocks: product.variants.first.stock,
                  imageFit: product.imageFit,
                  quantityStepSize: product.quantityStepSize,
                  minQty: product.minimumOrderQuantity,
                  totalAllowedQuantity: product.totalAllowedQuantity,
                  tieredPricing: product.variants.first.tieredPricing,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
