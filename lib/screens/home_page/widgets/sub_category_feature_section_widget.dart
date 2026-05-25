import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:grofery_user/l10n/app_localizations.dart';
import 'package:grofery_user/router/app_routes.dart';
import 'package:grofery_user/utils/widgets/custom_shimmer.dart';
import 'package:grofery_user/utils/widgets/custom_sub_category_card.dart';
import '../../product_listing_page/model/product_listing_type.dart';
import '../bloc/category/category_bloc.dart';
import '../bloc/category/category_state.dart';

class SubCategoryFeatureSectionWidget extends StatefulWidget {
  final bool showTitle;

  const SubCategoryFeatureSectionWidget({
    super.key,
    this.showTitle = true,
  });

  /// Static method to show all categories in a bottom sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.70,
          padding: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Small handle at the top of the modal
              Container(
                width: 60,
                height: 6,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Text(
                AppLocalizations.of(context)?.shopByCategories ??
                    "All Categories",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
              const SizedBox(height: 14),
              // Renders the category grid without the title
              const Expanded(
                child: SubCategoryFeatureSectionWidget(showTitle: false),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  State<SubCategoryFeatureSectionWidget> createState() =>
      _SubCategoryFeatureSectionWidgetState();
}

class _SubCategoryFeatureSectionWidgetState
    extends State<SubCategoryFeatureSectionWidget> {
  int _getCrossAxisCount(BuildContext context) {
    if (1.sw >= 1200) return 10;
    if (1.sw >= 800) return 6;
    if (1.sw >= 600) return 4;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (BuildContext context, CategoryState state) {
        if (state is CategoryLoaded) {
          Widget categoryContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showTitle)
                Padding(
                  padding: EdgeInsets.only(
                      left: 10.w, right: 10.w, bottom: 10.h, top: 10.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.shopByCategories ??
                            'Shop by categories',
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(8.r),
                        onTap: () {
                          SubCategoryFeatureSectionWidget.show(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          child: Text(
                            AppLocalizations.of(context)?.seeAll ?? 'See All',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.tertiary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.sp),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.only(left: 10.w, right: 10.w, bottom: 15.h),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _getCrossAxisCount(context),
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                  childAspectRatio: 0.65, // Ajusted to prevent overflow
                ),
                itemCount: state.categoryData.length >= 32
                    ? 32
                    : state.categoryData.length,
                itemBuilder: (context, index) {
                  final categoryData = state.categoryData[index];
                  return InkWell(
                    onTap: () {
                      GoRouter.of(context)
                          .push(AppRoutes.productListing, extra: {
                        'isTheirMoreCategory':
                            (categoryData.subcategoryCount ?? 0) > 0
                                ? true
                                : false,
                        'title': categoryData.title ?? '',
                        'logo': categoryData.image ?? '',
                        'totalProduct': categoryData.productCount,
                        'type': ProductListingType.category,
                        'identifier': categoryData.slug,
                      });
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: CustomSubCategoryCard(
                      categoryImage: categoryData.image ?? '',
                      categoryName: categoryData.title ?? '',
                    ),
                  );
                },
              ),
            ],
          );

          return state.categoryData.isNotEmpty
              ? SizedBox(
                  width: double.infinity,
                  child: widget.showTitle
                      ? categoryContent
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: categoryContent,
                        ),
                )
              : const SizedBox.shrink();
        } else if (state is CategoryLoading) {
          return SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w).copyWith(
                    top: 12.h,
                    bottom: 12.h,
                  ),
                  child: ShimmerWidget.rectangular(
                    isBorder: true,
                    height: 18.h,
                    width: 200.w,
                    borderRadius: 15.r,
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(context),
                    crossAxisSpacing: 10.w,
                    mainAxisSpacing: 10.h,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    return const ResponsiveSubCategoryCardShimmer();
                  },
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class ResponsiveSubCategoryCardShimmer extends StatelessWidget {
  const ResponsiveSubCategoryCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final cardHeight = constraints.maxHeight;
        final borderRadius = cardWidth * 0.12;

        return SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: Column(
            children: [
              Expanded(
                flex: 7,
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: cardHeight * 0.05),
                  child: ShimmerWidget.rectangular(
                    isBorder: true,
                    height: double.infinity,
                    width: double.infinity,
                    borderRadius: borderRadius,
                  ),
                ),
              ),
              // Text Shimmer
              Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShimmerWidget.rectangular(
                        isBorder: true,
                        height: 8.h,
                        width: double.infinity,
                        borderRadius: 4.r,
                      ),
                      SizedBox(height: cardHeight * 0.02),
                      ShimmerWidget.rectangular(
                        isBorder: true,
                        height: 8.h,
                        width: cardWidth * 0.6,
                        borderRadius: 4.r,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
