import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:grofery_user/config/theme.dart';
import '../model/get_cart_model.dart';
import 'package:grofery_user/services/user_cart/cart_validation.dart';
import 'package:grofery_user/utils/widgets/custom_toast.dart';

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

class CartItemWidget extends StatefulWidget {
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
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  late int localQuantity;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    localQuantity = widget.item.quantity ?? 1;
  }

  @override
  void didUpdateWidget(covariant CartItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isUpdating) {
      localQuantity = widget.item.quantity ?? 1;
    }
  }

  void _handleUpdate(int targetQty) {
    setState(() {
      localQuantity = targetQty;
      isUpdating = true;
    });
    
    widget.onQuantityChanged(widget.item.id.toString(), targetQty);
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final variant = widget.item.variant;
    final product = widget.item.product;
    final quantity = localQuantity;

    double activeUnitPrice = (variant?.specialPrice ?? 0).toDouble();
    bool isTierApplied = false;
    var activeTier;

    if (variant?.tieredPricing != null && variant!.tieredPricing!.isNotEmpty) {
      for (var tier in variant.tieredPricing!) {
        if (quantity >= tier.minQty) {
          activeUnitPrice = tier.price / tier.minQty;
          isTierApplied = tier.minQty > 1; // Only show bulk flag if it actually scales above 1
          activeTier = tier;
        }
      }
    }

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
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
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
                      "₹${(activeUnitPrice * quantity).toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: widget.priceColor ?? Colors.black,
                      ),
                    ),
                    if (!isTierApplied &&
                        (variant?.price ?? 0) >
                            (variant?.specialPrice ?? 0)) ...[
                      SizedBox(width: 8.w),
                      Text(
                        "₹${((variant?.price ?? 0) * quantity).toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 12.sp,
                          decoration: TextDecoration.lineThrough,
                          color: widget.originalPriceColor ?? Colors.grey,
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
    final itemId = widget.item.id.toString();
    final quantity = localQuantity;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(TablerIcons.minus,
                size: 16.sp, color: AppTheme.primaryColor),
            onPressed: () {
              final minQty = widget.item.product?.minimumOrderQuantity ?? 1;
              if (quantity <= minQty) {
                widget.onRemoveItem(itemId);
              } else {
                _handleUpdate(quantity - 1);
              }
            },
          ),
          Text(
            quantity.toString(),
            style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor),
          ),
          IconButton(
            icon: Icon(TablerIcons.plus,
                size: 16.sp, color: AppTheme.primaryColor),
            onPressed: () {
              final minQty = widget.item.product?.minimumOrderQuantity ?? 1;
              final maxQty = widget.item.product?.totalAllowedQuantity ?? 100;
              final stock = widget.item.variant?.stock ?? 100;

              final String? error = CartValidation.validateProductAddToCart(
                 context: context,
                 requestedQuantity: quantity + 1,
                 minQty: minQty,
                 maxQty: maxQty,
                 stock: stock,
                 isStoreOpen: true,
              );

              if (error != null) {
                 ToastManager.show(context: context, message: error, type: ToastType.error);
                 return;
              }

              _handleUpdate(quantity + 1);
            },
          ),
        ],
      ),
    );
  }
}
