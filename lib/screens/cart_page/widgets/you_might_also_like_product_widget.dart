import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../product_detail_page/model/product_detail_model.dart';
import '../../../utils/widgets/custom_product_card.dart';

class YouMightAlsoLikeProductWidget extends StatelessWidget {
  final List<ProductData>? productData;
  final int? addressId;
  final bool rushDelivery;
  final bool useWallet;
  final String? promoCode;
  final bool isFromCartPage;

  const YouMightAlsoLikeProductWidget({
    super.key,
    this.productData,
    this.addressId,
    this.rushDelivery = false,
    this.useWallet = false,
    this.promoCode,
    this.isFromCartPage = false,
  });

  @override
  Widget build(BuildContext context) {
    if (productData == null || productData!.isEmpty)
      return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Text(
            "You Might Also Like",
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 300.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: productData!.length,
            itemBuilder: (context, index) {
              final product = productData![index];
              return Container(
                width: 185.w,
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
    );
  }
}
