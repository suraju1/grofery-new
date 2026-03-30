import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grofery_user/utils/widgets/custom_image_container.dart';

class CustomSubCategoryCard extends StatelessWidget {
  final String categoryImage;
  final String categoryName;

  const CustomSubCategoryCard(
      {super.key, required this.categoryName, required this.categoryImage});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the available space from grid
        final cardWidth = constraints.maxWidth;

        return SizedBox(
          width: cardWidth,
          child: Column(
            children: [
              Expanded(
                flex: 7,
                child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSecondary,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    alignment: Alignment.center,
                    padding: EdgeInsets.all(6.w),
                    child: CustomImageContainer(
                      imagePath: categoryImage,
                      fit: BoxFit.contain,
                    )),
              ),
              SizedBox(
                height: 6.h,
              ),
              Expanded(
                flex: 3,
                child: categoryNameWidget(
                  categoryName: categoryName,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget categoryNameWidget({required String categoryName}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: Center(
        child: Text(
          categoryName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w500,
            height: 1.1,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
