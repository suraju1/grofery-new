import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../utils/widgets/custom_product_card.dart';
import '../model/featured_section_product_model.dart';

class ProductFeatureSectionWidget extends StatelessWidget {
  final FeatureSectionData? featureSectionData;
  final String? featureSectionTitle;
  final String? backgroundImage;
  final String? backgroundImageTablet;
  final String? featureSectionSlug;
  final String? featureSectionStyle;
  final String? backgroundColor;
  final String? backgroundType;
  final String? title; // Keep this for backward compatibility if used

  const ProductFeatureSectionWidget({
    super.key,
    this.featureSectionData,
    this.featureSectionTitle,
    this.backgroundImage,
    this.backgroundImageTablet,
    this.featureSectionSlug,
    this.featureSectionStyle,
    this.backgroundColor,
    this.backgroundType,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final section = featureSectionData;
    if (section == null || section.products == null || section.products!.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayTitle = featureSectionTitle?.isNotEmpty == true 
        ? featureSectionTitle 
        : (section.title ?? title ?? '');

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: backgroundColor != null ? _parseColor(backgroundColor!) : Colors.white,
        image: backgroundImage?.isNotEmpty == true
            ? DecorationImage(
                image: NetworkImage(backgroundImage!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              displayTitle!,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: section.textColor != null ? _parseColor(section.textColor!) : Colors.black,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 300.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: section.products!.length,
              itemBuilder: (context, index) {
                final product = section.products![index];
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
      ),
    );
  }

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.replaceFirst('#', '0xff')));
      }
      return Colors.transparent;
    } catch (e) {
      return Colors.transparent;
    }
  }
}
