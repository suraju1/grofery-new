import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:grofery_user/config/theme.dart';
import '../model/get_cart_model.dart';

class CartItemAttachment {
  final int productId;
  final String filePath;
  final String fileName;

  CartItemAttachment({
    required this.productId,
    required this.filePath,
    required this.fileName,
  });
}

class CartWidget extends StatelessWidget {
  final List<CartItems> items;
  final String deliveryTime;
  final void Function(String, int) onQuantityChanged;
  final void Function(String) onRemoveItem;
  final VoidCallback onAddMoreItems;
  final Color? backgroundColor;
  final Color? quantityButtonColor;
  final Color? priceColor;
  final Color? originalPriceColor;
  final int? totalItem;
  final int? addressId;
  final bool rushDelivery;
  final bool useWallet;
  final String? promoCode;

  const CartWidget({
    super.key,
    required this.items,
    required this.deliveryTime,
    required this.onQuantityChanged,
    required this.onRemoveItem,
    required this.onAddMoreItems,
    this.backgroundColor,
    this.quantityButtonColor,
    this.priceColor,
    this.originalPriceColor,
    this.totalItem,
    this.addressId,
    this.rushDelivery = false,
    this.useWallet = false,
    this.promoCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      padding: EdgeInsets.all(12.w),
      child: Column(
        children: [
          ...items.map((item) => CartItemWidget(
            item: item,
            onQuantityChanged: onQuantityChanged,
            onRemoveItem: onRemoveItem,
            quantityButtonColor: quantityButtonColor,
            priceColor: priceColor,
            originalPriceColor: originalPriceColor,
          )),
          SizedBox(height: 12.h),
          TextButton.icon(
            onPressed: onAddMoreItems,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text("Add more items"),
          ),
        ],
      ),
    );
  }
}

class CartItemWidget extends StatelessWidget {
  final CartItems item;
  final void Function(String, int) onQuantityChanged;
  final void Function(String) onRemoveItem;
  final Color? quantityButtonColor;
  final Color? priceColor;
  final Color? originalPriceColor;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemoveItem,
    this.quantityButtonColor,
    this.priceColor,
    this.originalPriceColor,
  });

  @override
  Widget build(BuildContext context) {
    final variant = item.variant;
    final product = item.product;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.network(
              product?.image ?? '',
              width: 60.w,
              height: 60.w,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?.name ?? '',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                ),
                if (variant?.title != null)
                  Text(
                    variant!.title!,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      "₹${variant?.specialPrice ?? 0}",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: priceColor ?? Colors.black,
                      ),
                    ),
                    if ((variant?.price ?? 0) > (variant?.specialPrice ?? 0)) ...[
                      SizedBox(width: 8.w),
                      Text(
                        "₹${variant?.price}",
                        style: TextStyle(
                          fontSize: 12.sp,
                          decoration: TextDecoration.lineThrough,
                          color: originalPriceColor ?? Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _buildQuantityStepper(context),
        ],
      ),
    );
  }

  Widget _buildQuantityStepper(BuildContext context) {
    final itemId = item.id.toString();
    final quantity = item.quantity ?? 1;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(TablerIcons.minus, size: 16.sp, color: AppTheme.primaryColor),
            onPressed: () {
              if (quantity > 1) {
                onQuantityChanged(itemId, quantity - 1);
              } else {
                onRemoveItem(itemId);
              }
            },
          ),
          Text(
            quantity.toString(),
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
          IconButton(
            icon: Icon(TablerIcons.plus, size: 16.sp, color: AppTheme.primaryColor),
            onPressed: () {
              onQuantityChanged(itemId, quantity + 1);
            },
          ),
        ],
      ),
    );
  }
}
