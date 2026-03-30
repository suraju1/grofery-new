import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../screens/product_detail_page/model/product_detail_model.dart';

void showVariantBottomSheet({
  required List<ProductVariants> variantsList,
  required ProductData productData,
  required String productImage,
  required num quantityStepSize,
  required BuildContext context,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        height: 400.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Variant",
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: ListView.builder(
                itemCount: variantsList.length,
                itemBuilder: (context, index) {
                  final variant = variantsList[index];
                  return ListTile(
                    leading: Image.network(variant.image.isNotEmpty ? variant.image : productImage, width: 40.w),
                    title: Text(variant.title),
                    subtitle: Text("₹${variant.specialPrice}"),
                    trailing: Radio<int>(
                      value: variant.id,
                      groupValue: productData.variants.firstWhere((v) => v.isDefault).id,
                      onChanged: (val) {
                        Navigator.pop(context);
                        // Add logic to select variant
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
