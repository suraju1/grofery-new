import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grofery_user/screens/my_orders/model/my_order_model.dart';
import 'package:intl/intl.dart';

class OrderDeliveryCard extends StatelessWidget {
  final MyOrdersData order;
  final VoidCallback onRateOrder;
  final VoidCallback onTrackOrder;
  final VoidCallback onReorder;

  const OrderDeliveryCard({
    super.key,
    required this.order,
    required this.onRateOrder,
    required this.onTrackOrder,
    required this.onReorder,
  });

  String formatOrderDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('dd MMM yy', 'en_US').format(dateTime); // e.g. 18 Jan 26
    } catch (e) {
      return dateStr;
    }
  }

  String formatOrderDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('dd MMM yy, hh:mm a', 'en_US').format(dateTime); // e.g. 18 Jan 26, 11:53 AM
    } catch (e) {
      return dateStr;
    }
  }

  String capitalize(String s) {
    if (s.isEmpty) return 'Pending';
    // Replace underscores and capitalize each word nicely
    return s
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  Widget _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icon(Icons.check_circle_rounded, color: const Color(0xFFE91E63), size: 20.sp);
      case 'cancelled':
        return Icon(Icons.cancel, color: Colors.red, size: 20.sp);
      default:
        return Icon(Icons.info, color: Colors.orange, size: 20.sp);
    }
  }

  Widget _buildBadge({
    required String text,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 9.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawStatusText = order.status ?? 'Pending';
    final statusText = rawStatusText.trim();
    final isDelivered = statusText.toLowerCase() == 'delivered';
    final isCancelled = statusText.toLowerCase() == 'cancelled';
    
    // Check if express
    final isExpress = order.fulfillmentType?.toLowerCase().contains('express') ?? false;

    // Status description for header
    String headerStatus = '';
    if (isDelivered) {
      headerStatus = 'Delivered on ${formatOrderDate(order.createdAt)}';
    } else if (isCancelled) {
      headerStatus = 'Order Cancelled';
    } else {
      headerStatus = '${capitalize(statusText)} on ${formatOrderDate(order.createdAt)}';
    }

    // Payment status text and badge config
    final rawPaymentStatus = order.paymentStatus ?? '';
    final isPaid = rawPaymentStatus.toLowerCase() == 'paid';
    final paymentText = isPaid ? 'PAID' : 'PAY ON DELIVERY';
    final paymentBgColor = isPaid ? const Color(0xFFE0F2F1) : const Color(0xFFF3E5F5);
    final paymentTextColor = isPaid ? const Color(0xFF00796B) : const Color(0xFF7B1FA2);

    // Delivery status badge config
    Color deliveryBgColor;
    Color deliveryTextColor;
    String deliveryText = capitalize(statusText).toUpperCase();
    if (isDelivered) {
      deliveryBgColor = const Color(0xFFE8F5E9);
      deliveryTextColor = const Color(0xFF2E7D32);
    } else if (isCancelled) {
      deliveryBgColor = const Color(0xFFFFEBEE);
      deliveryTextColor = const Color(0xFFC62828);
    } else {
      deliveryBgColor = const Color(0xFFFFF3E0);
      deliveryTextColor = const Color(0xFFEF6C00);
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _getStatusIcon(statusText),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              headerStatus,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isExpress) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF212529),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt, color: Colors.amber, size: 10.sp),
                                  SizedBox(width: 2.w),
                                  Text(
                                    'Express',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 8.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBadge(
                      text: paymentText,
                      backgroundColor: paymentBgColor,
                      textColor: paymentTextColor,
                    ),
                    SizedBox(height: 4.h),
                    _buildBadge(
                      text: deliveryText,
                      backgroundColor: deliveryBgColor,
                      textColor: deliveryTextColor,
                    ),
                  ],
                ),
              ],
            ),

            Divider(color: Colors.grey[100], height: 24.h),

            // Content section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.grey[600],
                            size: 16.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'Items: ${order.items?.length ?? 0}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Order ID: ${order.id}',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Ordered on ${formatOrderDateTime(order.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.monetization_on_outlined,
                          color: Colors.grey[600],
                          size: 16.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Price: ₹${order.finalTotal ?? order.totalPayable}',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            Divider(color: Colors.grey[100], height: 16.h),

            // Buttons / Actions Row (Re-order is ALWAYS visible now)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isDelivered) ...[
                  TextButton.icon(
                    onPressed: onRateOrder,
                    icon: Icon(Icons.star_outline, color: const Color(0xFFE91E63), size: 16.sp),
                    label: Text(
                      'Rate Order',
                      style: TextStyle(
                        color: const Color(0xFFE91E63),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                    ),
                  ),
                  SizedBox(width: 8.w),
                ] else if (!isCancelled) ...[
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: onTrackOrder,
                        icon: Icon(Icons.local_shipping_outlined, color: Colors.green, size: 16.sp),
                        label: Text(
                          'Track order',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ],
                TextButton.icon(
                  onPressed: onReorder,
                  icon: Icon(Icons.replay_rounded, color: const Color(0xFFE91E63), size: 16.sp),
                  label: Text(
                    'Re-order',
                    style: TextStyle(
                      color: const Color(0xFFE91E63),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}