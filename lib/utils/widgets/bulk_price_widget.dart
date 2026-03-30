import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../utils/widgets/price_utils.dart';

class BulkPriceLine {
  final double price;
  final int qty;
  final int addQty;

  BulkPriceLine({
    required this.price,
    required this.qty,
    required this.addQty,
  });
}

class BulkPriceWidget extends StatelessWidget {
  final List<BulkPriceLine> bulkPrices;
  final String unit;

  const BulkPriceWidget({
    super.key,
    required this.bulkPrices,
    this.unit = 'pc',
  });

  @override
  Widget build(BuildContext context) {
    if (bulkPrices.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(
            0xFFF0F7FF), // Light blue background matching screenshot
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: bulkPrices.asMap().entries.map((entry) {
          final index = entry.key;
          final bulk = entry.value;
          final isLast = index == bulkPrices.length - 1;

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: PriceUtils.formatPrice(bulk.price),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: '/$unit for ${bulk.qty} $unit s+'),
                      ],
                    ),
                  ),
                  Text(
                    'Add ${bulk.addQty}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Divider(
                    color: Colors.blue.shade100,
                    height: 1,
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
