import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:grofery_user/config/constant.dart';
import 'package:grofery_user/router/app_routes.dart';
import 'package:grofery_user/screens/home_page/bloc/brands/brands_bloc.dart';
import 'package:grofery_user/utils/widgets/custom_brands_card.dart';
import 'package:grofery_user/l10n/app_localizations.dart';
import 'package:grofery_user/utils/widgets/custom_shimmer.dart';
import '../../product_listing_page/model/product_listing_type.dart';

class BrandsSection extends StatefulWidget {
  final String brandsSectionTitle;
  final String categorySlug;

  const BrandsSection(
      {super.key,
      required this.brandsSectionTitle,
      required this.categorySlug});

  @override
  State<BrandsSection> createState() => _BrandsSectionState();
}

class _BrandsSectionState extends State<BrandsSection> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrandsBloc, BrandsState>(
      builder: (context, state) {
        if (state is BrandsLoaded) {
          return state.brandsData.isNotEmpty
              ? SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                            left: 10.0, right: 10.0, bottom: 4.0.h, top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.brandsSectionTitle,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(8.r),
                              onTap: () {
                                GoRouter.of(context)
                                    .push(AppRoutes.brandsListPage, extra: {
                                  'category-slug': widget.categorySlug
                                });
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6.w, vertical: 2.h),
                                child: Text(
                                  AppLocalizations.of(context)?.seeAll ??
                                      'See All',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15.sp),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: GridView.builder(
                          padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10.w,
                            mainAxisSpacing: 10.h,
                            childAspectRatio: 1.3,
                          ),
                          itemCount: state.brandsData.length > 6
                              ? 6
                              : state.brandsData.length,
                          itemBuilder: (context, index) {
                            final brandsData = state.brandsData[index];
                            return GestureDetector(
                              onTap: () {
                                GoRouter.of(context).push(
                                  AppRoutes.productListing,
                                  extra: {
                                    'isTheirMoreCategory': false,
                                    'title': brandsData.title,
                                    'logo': brandsData.logo,
                                    'totalProduct': 10,
                                    'type': ProductListingType.brand,
                                    'identifier': brandsData.slug,
                                  },
                                );
                              },
                              child: CustomBrandsCard(
                                brandName:
                                    state.brandsData[index].title ?? 'Brand',
                                brandImage: state.brandsData[index].logo ?? '',
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink();
        } else if (state is BrandsLoading) {
          return SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15.0,
                    vertical: 12.0,
                  ),
                  child: ShimmerWidget.rectangular(
                    isBorder: true,
                    height: 18,
                    width: 200,
                    borderRadius: 15,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10.w,
                      mainAxisSpacing: 10.h,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return ShimmerWidget.rectangular(
                        isBorder: true,
                        height: 80,
                        width: double.infinity,
                        borderRadius: 10,
                      );
                    },
                  ),
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
