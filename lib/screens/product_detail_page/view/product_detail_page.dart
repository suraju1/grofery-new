import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:grofery_user/l10n/app_localizations.dart';
import 'package:grofery_user/config/constant.dart';
import 'package:grofery_user/config/theme.dart';
import 'package:grofery_user/router/app_routes.dart';
import 'package:grofery_user/screens/cart_page/bloc/add_to_cart/add_to_cart_bloc.dart';
import 'package:grofery_user/screens/cart_page/bloc/add_to_cart/add_to_cart_state.dart';
import 'package:grofery_user/screens/product_detail_page/bloc/product_detail_bloc/product_detail_bloc.dart';
import 'package:grofery_user/screens/product_detail_page/bloc/product_review_bloc/product_review_bloc.dart';
import 'package:grofery_user/screens/product_detail_page/bloc/similar_product_bloc/similar_product_bloc.dart';
import 'package:grofery_user/screens/product_detail_page/model/product_detail_model.dart';
import 'package:grofery_user/screens/product_detail_page/widgets/app_bar_widget.dart';
import 'package:grofery_user/screens/product_detail_page/widgets/product_detail_shimmer.dart';
import 'package:grofery_user/screens/product_detail_page/widgets/review_rating_card.dart';
import 'package:grofery_user/utils/widgets/custom_button.dart';
import 'package:grofery_user/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:grofery_user/utils/widgets/custom_delivery_time_widget.dart';
import 'package:grofery_user/utils/widgets/custom_scaffold.dart';
import 'package:grofery_user/utils/widgets/dominant_colors.dart';
import 'package:grofery_user/utils/widgets/empty_states_page.dart';
import 'package:grofery_user/model/recent_product_model/recent_product_model.dart';
import 'package:grofery_user/model/user_cart_model/cart_sync_action.dart';
import 'package:grofery_user/services/recent_product/recent_product_service.dart';
import 'package:grofery_user/services/user_cart/cart_validation.dart';
import 'package:grofery_user/utils/widgets/custom_toast.dart';
import '../bloc/product_detail_bloc/product_detail_event.dart';
import '../bloc/product_detail_bloc/product_detail_state.dart';
import '../bloc/product_faq_bloc/product_faq_bloc.dart';
import '../widgets/rating_info_card.dart';
import '../widgets/similar_product_widget.dart';
import '../widgets/price_row_widget.dart';
import 'package:flutter/services.dart';
import 'package:grofery_user/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:grofery_user/bloc/user_cart_bloc/user_cart_event.dart';
import 'package:grofery_user/bloc/user_cart_bloc/user_cart_state.dart';
import 'package:grofery_user/model/user_cart_model/user_cart.dart';
import 'package:grofery_user/model/tiered_pricing.dart';
import 'package:grofery_user/utils/widgets/animated_button.dart';
import 'package:grofery_user/utils/widgets/price_utils.dart';

class ProductDetailPage extends StatefulWidget {
  final String productSlug;
  final ProductInitialData initialData;
  final VoidCallback? closeContainer;

  const ProductDetailPage(
      {super.key,
      required this.productSlug,
      required this.initialData,
      this.closeContainer});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  Map<String, SwatchValues> selectedVariants = {};
  bool _showTitle = false;

  List<String> productSlugList = [];

  ProductVariants? _currentVariant;

  ProductVariants _getActiveVariant(ProductData product) {
    if (selectedVariants.isEmpty) {
      return product.variants.firstWhere(
        (v) => v.isDefault,
        orElse: () => product.variants.first,
      );
    }

    return product.variants.firstWhere(
      (v) {
        // Match ALL selected attributes using their slugs
        for (var attr in product.attributes) {
          final selected = selectedVariants[attr.name];
          if (selected != null) {
            final variantValue = v.attributes[attr.slug];
            if (variantValue?.toString().toLowerCase().trim() !=
                selected.value.toString().toLowerCase().trim()) {
              return false;
            }
          }
        }
        return true;
      },
      orElse: () => product.variants
          .firstWhere((v) => v.isDefault, orElse: () => product.variants.first),
    );
  }

  @override
  void initState() {
    super.initState();
    productSlugList.add(widget.productSlug);
    _scrollController.addListener(_onScroll);
  }

  void _onProductViewed(
      String id, String name, String imageUrl, String slug) async {
    final product = RecentProduct(
      id: id,
      name: name,
      imageUrl: imageUrl,
      productSlug: slug,
    );
    await RecentlyViewedService.addProduct(product);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Attach once when the tree is built
    PrimaryScrollController.of(context).addListener(_onScroll);
  }

  void _onScroll() {
    final offset = PrimaryScrollController.of(context).offset;
    final show = offset > 200;
    if (_showTitle != show) {
      setState(() => _showTitle = show);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, String> getSelectedVariantsForApi() {
    return selectedVariants.map((key, value) => MapEntry(key, value.value));
  }

  UserCart? _getCartItem(
      CartState state, int productId, int productVariantId, int storeId) {
    List<UserCart> items = [];
    if (state is CartLoaded) {
      items = state.items;
    } else if (state is CartLoading) {
      items = state.items;
    } else {
      return null;
    }

    for (var item in items) {
      if ((int.tryParse(item.productId) ?? 0) == productId &&
          (int.tryParse(item.variantId) ?? 0) == productVariantId &&
          (int.tryParse(item.vendorId) ?? 0) == storeId) {
        return item;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ProductDetailBloc()
            ..add(FetchProductDetail(productSlug: widget.productSlug)),
        ),
        BlocProvider(
          create: (_) => ProductReviewBloc()
            ..add(FetchProductReview(productSlug: widget.productSlug)),
        ),
        BlocProvider(
          create: (_) => ProductFAQBloc()
            ..add(FetchProductFAQ(productSlug: widget.productSlug)),
        ),
        BlocProvider(
          create: (_) => SimilarProductBloc()
            ..add(
                FetchSimilarProduct(excludeProductSlug: [widget.productSlug])),
        ),
      ],
      child: CustomScaffold(
        showViewCart: true,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        body: BlocListener<AddToCartBloc, AddToCartState>(
          listener: (BuildContext context, AddToCartState state) {},
          child: BlocBuilder<ProductDetailBloc, ProductDetailState>(
            builder: (BuildContext context, ProductDetailState state) {
              if (state is ProductDetailLoading) {
                // Show shimmer loading with AppBar
                return NestedScrollView(
                  headerSliverBuilder:
                      (BuildContext context, bool innerBoxIsScrolled) {
                    return [
                      AppBarWidget(
                        showTitle: false,
                        initialData: widget.initialData,
                        loadedProduct: null,
                      )
                    ];
                  },
                  body: ProductDetailShimmer(),
                );
              } else if (state is ProductDetailLoaded) {
                final product = state.productData[0];

                _currentVariant ??= product.variants.firstWhere(
                  (v) => v.isDefault,
                  orElse: () => product.variants.first,
                );

                // Initialize selectedVariants if empty from the current variant
                if (selectedVariants.isEmpty && _currentVariant != null) {
                  for (var attr in product.attributes) {
                    final variantAttrValue =
                        _currentVariant!.attributes[attr.slug];

                    if (variantAttrValue != null) {
                      try {
                        final sw = attr.swatchValues.firstWhere(
                          (s) =>
                              s.value.toString().toLowerCase().trim() ==
                              variantAttrValue.toString().toLowerCase().trim(),
                        );
                        selectedVariants[attr.name] = sw;
                      } catch (_) {
                        selectedVariants[attr.name] = SwatchValues(
                            value: variantAttrValue.toString(), swatch: '');
                      }
                    }
                  }
                }

                var activeVariant = _getActiveVariant(product);

                _onProductViewed(product.id.toString(), product.title,
                    product.mainImage, product.slug);

                return NestedScrollView(
                  headerSliverBuilder:
                      (BuildContext context, bool innerBoxIsScrolled) {
                    return [
                      AppBarWidget(
                        showTitle: _showTitle,
                        initialData: widget.initialData,
                        loadedProduct: product,
                        selectedVariant: activeVariant,
                      )
                    ];
                  },
                  body: CustomScrollView(
                    clipBehavior: Clip.antiAlias,
                    physics: ClampingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            Container(
                              color: Theme.of(context).colorScheme.surface,
                              padding: const EdgeInsets.only(
                                  top: 15, left: 12, right: 12, bottom: 8),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          product.title,
                                          style: TextStyle(
                                            fontSize:
                                                isTablet(context) ? 24 : 13.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      _buildQuickDeliveryBadge(product.quickDeliveryAvailable),
                                    ],
                                  ),

                                  // Inline version — no Positioned needed
                                  if (int.parse(product.itemTotalInCart) > 0)
                                    Align(
                                      alignment: AlignmentGeometry.topLeft,
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 8.h),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10.w, vertical: 4.h),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(5.r),
                                          ),
                                          child: Text(
                                            '🛍️ ${product.itemTotalInCart} ${AppLocalizations.of(context)!.inCart}',
                                            style: TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              RatingBar.builder(
                                                initialRating: double.parse(
                                                    product.ratings.toString()),
                                                minRating: 1,
                                                direction: Axis.horizontal,
                                                allowHalfRating: true,
                                                itemCount: 5,
                                                itemSize: 18,
                                                itemBuilder: (context, _) =>
                                                    Icon(
                                                  AppTheme.ratingStarIconFilled,
                                                  color:
                                                      AppTheme.ratingStarColor,
                                                ),
                                                ignoreGestures: true,
                                                onRatingUpdate: (rating) {},
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${product.ratings}/5 ',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .tertiary
                                                      .withValues(alpha: 0.8),
                                                ),
                                              ),
                                              Text('(${product.ratingCount})')
                                            ],
                                          ),
                                          SizedBox(height: 10.h),
                                          BlocBuilder<CartBloc, CartState>(
                                            builder: (context, cartState) {
                                              final cartItem = _getCartItem(
                                                  cartState,
                                                  product.id,
                                                  activeVariant.id,
                                                  activeVariant.storeId);
                                              final currentQty =
                                                  cartItem?.quantity ?? 0;
                                              final effectivePrice =
                                                  activeVariant
                                                      .getEffectivePrice(
                                                          currentQty);
                                              final displayQty = currentQty > 0
                                                  ? currentQty
                                                  : (product.minimumOrderQuantity > 0
                                                      ? product.minimumOrderQuantity
                                                      : 1);
                                              final totalPrice =
                                                  effectivePrice * displayQty;
                                              final double totalOriginalPrice =
                                                  (activeVariant.mrpStatus ==
                                                              1 &&
                                                          activeVariant.mrp > 0)
                                                      ? (activeVariant.mrp *
                                                          displayQty)
                                                      : 0.0;

                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  PriceRowWidget(
                                                    originalPrice:
                                                        totalOriginalPrice,
                                                    salePrice:
                                                        totalPrice.toDouble(),
                                                    fontSize: 12.sp,
                                                    originalFontSize: 10.sp,
                                                    discountFontSize: 8.sp,
                                                    fontWeight: FontWeight.w700,
                                                    originalPriceColor:
                                                        Colors.grey.shade600,
                                                    discountBackgroundColor:
                                                        Colors.green.shade600,
                                                    discountTextColor:
                                                        Colors.white,
                                                  ),
                                                  if (product
                                                          .minimumOrderQuantity >
                                                      1)
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                          top: 2.h, bottom: 4.h),
                                                      child: Text(
                                                        "${PriceUtils.formatPrice(effectivePrice.toDouble())} per pc",
                                                        style: TextStyle(
                                                          fontSize: 14.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.grey
                                                              .shade700,
                                                        ),
                                                      ),
                                                    ),
                                                  if (product
                                                          .minimumOrderQuantity >
                                                      1)
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                          top: 4.h),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                              Icons
                                                                  .info_outline,
                                                              size: 14.sp,
                                                              color: AppTheme
                                                                  .primaryColor),
                                                          SizedBox(width: 4.w),
                                                          Text(
                                                            "Minimum Order: ${product.minimumOrderQuantity} ${product.minimumOrderQuantity > 1 ? 'pcs' : 'pc'}",
                                                            style: TextStyle(
                                                              fontSize: 11.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: AppTheme
                                                                  .primaryColor,
                                                              letterSpacing:
                                                                  0.2,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  _buildTieredPricingSection(
                                      product, activeVariant),
                                  // VARIANTS
                                  ListView.builder(
                                    padding: EdgeInsets.zero,
                                    physics: NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: product.attributes.length,
                                    itemBuilder: (context, index) {
                                      return variantWidget(
                                        label: product.attributes[index].name,
                                        variantType: product
                                            .attributes[index].swatcheType,
                                        selectedValue: selectedVariants[
                                            product.attributes[index].name],
                                        onSelected: (SwatchValues value) {
                                          setState(() {
                                            selectedVariants[product
                                                .attributes[index]
                                                .name] = value;
                                          });

                                          log('Valu Valu  ${value.value}');
                                        },
                                        productAttributes: product
                                            .attributes[index].swatchValues,
                                      );
                                    },
                                  ),
                                  Divider(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),

                                  // Expandable description
                                  ExpansionTile(
                                    expansionAnimationStyle: AnimationStyle(
                                      duration:
                                          const Duration(milliseconds: 350),
                                      curve: Curves.easeInOutCubic,
                                      reverseDuration:
                                          const Duration(milliseconds: 250),
                                    ),
                                    title: Text(
                                      l10n.viewProductDetails,
                                      style: TextStyle(
                                        fontSize:
                                            isTablet(context) ? 18 : 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary,
                                      ),
                                    ),
                                    collapsedIconColor:
                                        Theme.of(context).colorScheme.tertiary,
                                    iconColor:
                                        Theme.of(context).colorScheme.tertiary,
                                    initiallyExpanded: false,
                                    tilePadding:
                                        EdgeInsets.symmetric(horizontal: 0.w),
                                    childrenPadding: EdgeInsets.symmetric(
                                      horizontal: 0.w,
                                    ),
                                    shape: const Border(),
                                    children: [
                                      Divider(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline
                                            .withValues(alpha: 0.5),
                                        thickness: 1,
                                      ),
                                      SizedBox(
                                        height: 12,
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 0.w, vertical: 0.h),
                                        child: Column(
                                          children: _buildSpecTableRows(
                                              context, product, l10n),
                                        ),
                                      ),
                                      Html(
                                        data: product.description,
                                        shrinkWrap: true,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 9.h),

                            // Store Name
                            sellerStoreName(
                              storeName: product.variants.first.storeName,
                              storeSlug: product.variants.first.storeSlug,
                              sellerName: product.seller,
                            ),

                            // Customer Review
                            BlocBuilder<ProductReviewBloc, ProductReviewState>(
                              builder: (BuildContext context,
                                  ProductReviewState state) {
                                if (state is ProductReviewLoaded) {
                                  if (state.productReview.first.data
                                              .totalReviews >
                                          0 ||
                                      state.productReview.first.data.reviews
                                          .isNotEmpty) {
                                    return Column(
                                      children: [
                                        Card(
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(0.r),
                                          ),
                                          margin: EdgeInsets.only(
                                              left: 0.w, right: 0.w, top: 12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  left: 10.w,
                                                  right: 10.w,
                                                  top: 10.w,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      l10n.customerReviews,
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .tertiary,
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        GoRouter.of(context).push(
                                                            AppRoutes
                                                                .reviewRatingPage,
                                                            extra: {
                                                              'productSlug':
                                                                  product.slug
                                                            });
                                                      },
                                                      child: Text(
                                                        l10n.seeAll,
                                                        style: TextStyle(
                                                          fontSize: 12.sp,
                                                          color: AppTheme
                                                              .primaryColor,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (state.productReview.first.data
                                                      .totalReviews >
                                                  0)
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 15.w,
                                                      vertical: 8.h),
                                                  child: RatingInfoCard(
                                                      reviewModel: state
                                                          .productReview.first),
                                                ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 0.w,
                                                  vertical: 12.w,
                                                ),
                                                child: LayoutBuilder(
                                                  builder:
                                                      (context, constraints) {
                                                    return SingleChildScrollView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      physics:
                                                          BouncingScrollPhysics(),
                                                      padding: EdgeInsets.only(
                                                          right: 12.w),
                                                      child: IntrinsicHeight(
                                                        child: Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .stretch,
                                                          children: state
                                                              .productReview
                                                              .first
                                                              .data
                                                              .reviews
                                                              .take(5)
                                                              .toList()
                                                              .asMap()
                                                              .entries
                                                              .map((entry) {
                                                            int index =
                                                                entry.key;
                                                            var review =
                                                                entry.value;
                                                            return SizedBox(
                                                              width: 280.w,
                                                              child:
                                                                  ReviewRatingCard(
                                                                rating: review
                                                                    .rating
                                                                    .toDouble(),
                                                                date: review
                                                                    .createdAt,
                                                                reviewText:
                                                                    review
                                                                        .comment,
                                                                index: index,
                                                                images: review
                                                                    .reviewImages,
                                                                maxLines: 10,
                                                              ),
                                                            );
                                                          }).toList(),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 9.h),
                                      ],
                                    );
                                  }
                                  return SizedBox.shrink();
                                }
                                return SizedBox.shrink();
                              },
                            ),

                            BlocBuilder<ProductFAQBloc, ProductFAQState>(
                              builder: (BuildContext context,
                                  ProductFAQState state) {
                                if (state is ProductFAQLoaded) {
                                  final faqData = state.productData.first.data;
                                  return faqData.isNotEmpty
                                      ? Column(
                                          children: [
                                            Card(
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(0.r),
                                              ),
                                              margin: EdgeInsets.symmetric(
                                                  horizontal: 0.w,
                                                  vertical: 0.h),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                      left: 10.w,
                                                      right: 10.w,
                                                      top: 10.w,
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          l10n.questionAndAnswers,
                                                          style: TextStyle(
                                                            fontSize: 14.sp,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .tertiary,
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          onTap: () {
                                                            GoRouter.of(context)
                                                                .push(
                                                                    AppRoutes
                                                                        .faqPage,
                                                                    extra: {
                                                                  'productSlug':
                                                                      product
                                                                          .slug
                                                                });
                                                          },
                                                          child: Text(
                                                            l10n.seeAll,
                                                            style: TextStyle(
                                                              fontSize: 12.sp,
                                                              color: AppTheme
                                                                  .primaryColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 0.w,
                                                      vertical: 12.w,
                                                    ),
                                                    child:
                                                        SingleChildScrollView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      physics:
                                                          BouncingScrollPhysics(),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: List.generate(
                                                          faqData.length > 5
                                                              ? 5
                                                              : faqData.length,
                                                          (index) {
                                                            final qa =
                                                                faqData[index];
                                                            return Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .only(
                                                                right: index ==
                                                                        (faqData.length -
                                                                            1)
                                                                    ? 0.w
                                                                    : 12.w,
                                                                left: index == 0
                                                                    ? 12.w
                                                                    : 0.w,
                                                              ),
                                                              child:
                                                                  GestureDetector(
                                                                onTap: () {
                                                                  GoRouter.of(
                                                                          context)
                                                                      .push(
                                                                          AppRoutes
                                                                              .faqPage,
                                                                          extra: {
                                                                        'productSlug':
                                                                            product.slug
                                                                      });
                                                                },
                                                                child:
                                                                    _buildQAItem(
                                                                  question: qa
                                                                      .question,
                                                                  answer:
                                                                      qa.answer,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                      : SizedBox.shrink();
                                }
                                return SizedBox.shrink();
                              },
                            ),

                            SizedBox(height: 9.h),

                            BlocBuilder<SimilarProductBloc,
                                SimilarProductState>(builder: (context, state) {
                              if (state is SimilarProductLoaded) {
                                return SimilarProductWidget(
                                    product: state.similarProduct);
                              }
                              return SizedBox.shrink();
                            }),
                            SizedBox(height: 120.h),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (state is ProductDetailFailed) {
                return NoProductPage();
              }
              return CustomCircularProgressIndicator();
            },
          ),
        ),
        bottomNavigationBar: BlocBuilder<ProductDetailBloc, ProductDetailState>(
          builder: (context, state) {
            if (state is! ProductDetailLoaded) {
              return SizedBox.shrink();
            }

            final product = state.productData[0];
            final activeVariant = _getActiveVariant(product);

            return Container(
              height: 100,
              decoration: BoxDecoration(
                color: isDarkMode(context)
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.white,
                boxShadow: [
                  // Main bottom shadow
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: Offset(0, 4),
                  ),
                  // Ambient/soft shadow for depth
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: Offset(0, 2),
                  ),
                  // Optional: subtle top ambient lift (removes flat look)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    spreadRadius: 0,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  BlocBuilder<CartBloc, CartState>(
                    builder: (context, cartState) {
                      final cartItem = _getCartItem(cartState, product.id,
                          activeVariant.id, activeVariant.storeId);
                      final currentQty = cartItem?.quantity ?? 0;
                      final effectivePrice =
                          activeVariant.getEffectivePrice(currentQty);
                      final displayQty = currentQty > 0
                          ? currentQty
                          : (product.minimumOrderQuantity > 0
                              ? product.minimumOrderQuantity
                              : 1);
                      final totalPrice = effectivePrice * displayQty;

                      final double totalOriginalPrice =
                          (activeVariant.mrpStatus == 1 &&
                                  activeVariant.mrp > 0)
                              ? (activeVariant.mrp * displayQty)
                              : 0.0;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PriceRowWidget(
                            originalPrice: totalOriginalPrice,
                            salePrice: totalPrice.toDouble(),
                            fontSize: 12.sp,
                            originalFontSize: 10.sp,
                            discountFontSize: 8.sp,
                            fontWeight: FontWeight.w700,
                            originalPriceColor: Colors.grey.shade600,
                          ),
                          if (product.minimumOrderQuantity > 1)
                            Text(
                              "${PriceUtils.formatPrice(effectivePrice.toDouble())} per pc",
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          Text(
                            l10n.inclusiveOfAllTax,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (product.minimumOrderQuantity > 1)
                            Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Text(
                                "Min Order: ${product.minimumOrderQuantity} ${product.minimumOrderQuantity > 1 ? 'pcs' : 'pc'}",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                    ],
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  if (activeVariant.stock > 0)
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: 120,
                            minWidth: 80,
                          ),
                          child: BlocBuilder<CartBloc, CartState>(
                            builder: (context, cartState) {
                              final int productId = product.id;
                              final int productVariantId = activeVariant.id;
                              final int storeId = activeVariant.storeId;

                              final cartItem = _getCartItem(cartState,
                                  productId, productVariantId, storeId);
                              final isInCart = cartItem != null;
                              final int currentQty = cartItem?.quantity ?? 0;

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                height: 45,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isInCart
                                      ? AppTheme.primaryColor
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  transitionBuilder: (Widget child,
                                      Animation<double> animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: ScaleTransition(
                                        scale:
                                            Tween<double>(begin: 0.85, end: 1.0)
                                                .animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: isInCart
                                      ? Container(
                                          key: const ValueKey('stepper_inner'),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            borderRadius:
                                                BorderRadius.circular(10.r),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              GestureDetector(
                                                onTap: () async {
                                                  await HapticFeedback
                                                      .lightImpact();

                                                  final int targetQty =
                                                      currentQty - 1;

                                                  if (targetQty <
                                                      product
                                                          .minimumOrderQuantity) {
                                                    // If going below minimum order quantity, remove from cart
                                                    if (context.mounted) {
                                                      context
                                                          .read<CartBloc>()
                                                          .add(
                                                            RemoveFromCart(
                                                                cartKey: cartItem
                                                                    .cartKey,
                                                                context:
                                                                    context),
                                                          );
                                                    }
                                                  } else {
                                                    if (context.mounted) {
                                                      context
                                                          .read<CartBloc>()
                                                          .add(
                                                            UpdateCartQty(
                                                                cartKey: cartItem
                                                                    .cartKey,
                                                                quantity:
                                                                    targetQty,
                                                                cartItemId: cartItem
                                                                    .serverCartItemId,
                                                                context:
                                                                    context),
                                                          );
                                                    }
                                                  }
                                                },
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 10.w),
                                                  child: Icon(
                                                    TablerIcons.minus,
                                                    size: 20.r,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                cartItem.quantity.toString(),
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () async {
                                                  await HapticFeedback
                                                      .lightImpact();

                                                  final int targetQty =
                                                      currentQty + 1;

                                                  if (context.mounted) {
                                                    final error = CartValidation
                                                        .validateProductAddToCart(
                                                      context: context,
                                                      requestedQuantity:
                                                          targetQty,
                                                      minQty: product
                                                          .minimumOrderQuantity,
                                                      maxQty: product
                                                          .totalAllowedQuantity,
                                                      stock:
                                                          activeVariant.stock,
                                                      isStoreOpen: product
                                                          .storeStatus!.isOpen,
                                                    );

                                                    if (error != null) {
                                                      ToastManager.show(
                                                          context: context,
                                                          message: error,
                                                          type:
                                                              ToastType.error);
                                                      return;
                                                    } else {
                                                      context
                                                          .read<CartBloc>()
                                                          .add(
                                                            UpdateCartQty(
                                                                cartKey: cartItem
                                                                    .cartKey,
                                                                quantity:
                                                                    targetQty,
                                                                cartItemId: cartItem
                                                                    .serverCartItemId,
                                                                context:
                                                                    context),
                                                          );
                                                    }
                                                  }
                                                },
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 10.w),
                                                  child: Icon(
                                                    TablerIcons.plus,
                                                    size: 20.r,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : SizedBox(
                                          key: const ValueKey(
                                              'add_button_inner'),
                                          height: 45,
                                          width: double.infinity,
                                          child: CustomButton(
                                            onPressed: () {
                                              final cartBloc =
                                                  context.read<CartBloc>();
                                              final existingItem = _getCartItem(
                                                  cartBloc.state,
                                                  product.id,
                                                  activeVariant.id,
                                                  activeVariant.storeId);
                                              if (existingItem != null) {
                                                cartBloc.add(RemoveFromCart(
                                                    cartKey:
                                                        existingItem.cartKey,
                                                    context: context));
                                                return;
                                              }
                                              // 1️⃣ Auth check
                                              /*if (Global.userData == null) {
                                        AuthGuard.ensureLoggedIn(context);
                                        return;
                                      }*/

                                              final isStoreOpen =
                                                  product.storeStatus?.isOpen ??
                                                      true;

                                              final selectedVariant =
                                                  activeVariant;

                                              // 4️⃣ PRODUCT VALIDATION (Toggle check already handled above)
                                              final requestedQty = (product
                                                          .minimumOrderQuantity >
                                                      0
                                                  ? product.minimumOrderQuantity
                                                  : 1);

                                              final productError =
                                                  CartValidation
                                                      .validateProductAddToCart(
                                                context: context,
                                                requestedQuantity: requestedQty,
                                                minQty: product
                                                    .minimumOrderQuantity,
                                                maxQty: product
                                                    .totalAllowedQuantity,
                                                stock: selectedVariant.stock,
                                                isStoreOpen: isStoreOpen,
                                              );

                                              if (productError != null) {
                                                ToastManager.show(
                                                  context: context,
                                                  message: productError,
                                                  type: ToastType.error,
                                                );
                                                return;
                                              }

                                              // 5️⃣ Create cart item
                                              final item = UserCart(
                                                productId:
                                                    product.id.toString(),
                                                variantId: selectedVariant.id
                                                    .toString(),
                                                variantName:
                                                    selectedVariant.title,
                                                vendorId: selectedVariant
                                                    .storeId
                                                    .toString(),
                                                name: product.title,
                                                image: product.mainImage,
                                                price: selectedVariant
                                                    .getEffectivePrice(
                                                        requestedQty),
                                                originalPrice: selectedVariant
                                                    .price
                                                    .toDouble(),
                                                quantity: requestedQty,
                                                serverCartItemId: null,
                                                syncAction: CartSyncAction.add,
                                                updatedAt: DateTime.now(),
                                                minQty: product
                                                    .minimumOrderQuantity,
                                                maxQty: product
                                                    .totalAllowedQuantity,
                                                isOutOfStock:
                                                    selectedVariant.stock <= 0,
                                                isSynced: false,
                                                tieredPricing: selectedVariant
                                                    .tieredPricing,
                                              );

                                              // 6️⃣ Add to cart
                                              cartBloc.add(AddToCart(
                                                  item: item,
                                                  context: context));
                                            },
                                            child: Text(
                                              l10n.add,
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                            color: AppTheme.primaryColor, width: 1.w),
                      ),
                      child: Text(
                        l10n.outOfStock,
                        style: TextStyle(
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTieredPricingSection(
      ProductData product, ProductVariants activeVariant) {
    if (activeVariant.tieredPricing.isEmpty) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        final cartItem = _getCartItem(
            cartState, product.id, activeVariant.id, activeVariant.storeId);
        final currentQty = cartItem?.quantity ?? 0;

        TieredPricing? activeTier;
        for (var tier in activeVariant.tieredPricing) {
          if (currentQty >= tier.minQty) {
            if (activeTier == null || tier.minQty > activeTier.minQty) {
              activeTier = tier;
            }
          }
        }

        return Container(
          margin: EdgeInsets.symmetric(vertical: 8.h),
          padding: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F8FE), // Light blue background
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children:
                List.generate(activeVariant.tieredPricing.length, (index) {
              final tier = activeVariant.tieredPricing[index];
              final bool isSelectedTier = activeTier == tier;
              final bool isExactMatch = currentQty == tier.minQty;

              // Calculation: (BasePricePerUnit * currentQty) - (TierUnitPrice * currentQty)
              final double unitBasePrice = activeVariant.price /
                  (product.quantityStepSize > 0 ? product.quantityStepSize : 1);
              final double tierUnitPrice = tier.price / tier.minQty;

              // Use current quantity for savings display
              final int effectiveQty =
                  isSelectedTier ? currentQty : tier.minQty;
              final double savings =
                  (unitBasePrice - tierUnitPrice) * effectiveQty;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: isSelectedTier
                      ? const Color(0xFFE7F6EB)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isSelectedTier
                        ? const Color(0xFFB9E4C2)
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: () => _onTieredAddToCart(
                      product, activeVariant, tier.minQty,
                      isSetAbsolute: true),
                  borderRadius: BorderRadius.circular(10.r),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "₹${tierUnitPrice.toStringAsFixed(2)}/pc for ${tier.minQty} pcs+",
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isSelectedTier
                                      ? const Color(0xFF1D8936)
                                      : const Color(0xFF1E5BB2),
                                ),
                              ),
                              if (isSelectedTier && savings > 0)
                                Padding(
                                  padding: EdgeInsets.only(top: 4.h),
                                  child: Text(
                                    "₹${savings.toStringAsFixed(2)} saved on $currentQty pcs",
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1D8936),
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  "Total: ₹${tier.price.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1E5BB2)
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isSelectedTier)
                          Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1D8936),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              size: 16.sp,
                              color: Colors.white,
                            ),
                          )
                        else
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 5.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                  color: const Color(0xFFEAB9BC), width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Add ${tier.minQty}",
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFE54A50),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Icon(
                                  TablerIcons.plus,
                                  size: 18.sp,
                                  color: const Color(0xFFE54A50),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  void _onTieredAddToCart(
      ProductData product, ProductVariants variant, int quantity,
      {bool isSetAbsolute = false}) {
    final cartBloc = context.read<CartBloc>();
    final cartState = cartBloc.state;
    final cartItem =
        _getCartItem(cartState, product.id, variant.id, variant.storeId);

    final isStoreOpen = product.storeStatus?.isOpen ?? true;
    final int currentQty = cartItem?.quantity ?? 0;

    int targetQty;

    if (isSetAbsolute) {
      // Quick Select behavior: If already at this exact quantity, remove. Otherwise, set to it.
      if (currentQty == quantity) {
        targetQty = 0;
      } else {
        targetQty = quantity;
      }
    } else {
      // Stepper behavior (Additive/Subtractive)
      targetQty = currentQty + quantity;
    }

    HapticFeedback.lightImpact();

    if (targetQty <= 0) {
      if (cartItem != null) {
        cartBloc
            .add(RemoveFromCart(cartKey: cartItem.cartKey, context: context));
      }
      return;
    }

    final productError = CartValidation.validateProductAddToCart(
      context: context,
      requestedQuantity: targetQty,
      minQty: product.minimumOrderQuantity,
      maxQty: product.totalAllowedQuantity,
      stock: variant.stock,
      isStoreOpen: isStoreOpen,
    );

    if (productError != null) {
      ToastManager.show(
        context: context,
        message: productError,
        type: ToastType.error,
      );
      return;
    }

    // Always use getEffectivePrice for consistency
    final double unitPrice = variant.getEffectivePrice(targetQty);

    if (cartItem != null) {
      cartBloc.add(UpdateCartQty(
        cartKey: cartItem.cartKey,
        quantity: targetQty,
        cartItemId: cartItem.serverCartItemId,
        context: context,
      ));
    } else {
      final item = UserCart(
        productId: product.id.toString(),
        variantId: variant.id.toString(),
        variantName: variant.title,
        vendorId: variant.storeId.toString(),
        name: product.title,
        image: product.mainImage,
        price: unitPrice,
        originalPrice: variant.price,
        quantity: targetQty,
        serverCartItemId: null,
        syncAction: CartSyncAction.add,
        updatedAt: DateTime.now(),
        minQty: product.minimumOrderQuantity,
        maxQty: product.totalAllowedQuantity,
        isOutOfStock: variant.stock <= 0,
        isSynced: false,
        tieredPricing: variant.tieredPricing,
      );
      cartBloc.add(AddToCart(item: item, context: context));
    }
  }

  List<Widget> _buildSpecTableRows(
    BuildContext context,
    ProductData product,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.tertiary;
    final labelColor = textColor.withValues(alpha: 0.75);
    final valueColor = textColor.withValues(alpha: 0.95);

    final List<MapEntry<String, String>> specs = [];

    if (product.brand.isNotEmpty) {
      specs.add(MapEntry(l10n.brand, product.brand));
    }
    if (product.category.isNotEmpty) {
      specs.add(MapEntry(l10n.category, product.category));
    }
    specs.add(MapEntry(
      l10n.packOf,
      '${product.quantityStepSize} ${product.quantityStepSize > 1 ? 'Units' : 'Unit'}',
    ));

    if (product.madeIn.isNotEmpty) {
      specs.add(MapEntry(l10n.madeIn, product.madeIn));
    }
    if (product.indicator.isNotEmpty) {
      specs.add(MapEntry(
        l10n.indicator,
        removeUnderscores(capitalizeFirstLetter(product.indicator)),
      ));
    }

    // Guarantee & Warranty
    final guarantee = product.guaranteePeriod.toString();
    if (guarantee.isNotEmpty && guarantee != '0') {
      specs.add(MapEntry(l10n.guaranteePeriod, guarantee));
    }

    final warranty = product.warrantyPeriod.toString();
    if (warranty.isNotEmpty && warranty != '0') {
      specs.add(MapEntry(l10n.warrantyPeriod, warranty));
    }

    // Returnable
    final isReturnable =
        product.isReturnable == 1 || product.isReturnable.toString() == '1';
    specs.add(MapEntry(
      l10n.returnable,
      isReturnable ? l10n.yes : l10n.na,
    ));

    // ── All custom fields ─────────────────────────────────────────────────
    for (final field in product.customFields) {
      final valueStr = field.value?.toString().trim() ?? '';
      if (valueStr.isNotEmpty) {
        specs.add(MapEntry(field.key, valueStr));
      }
    }

    if (specs.isEmpty) {
      return [SizedBox.shrink()];
    }

    // Build striped table rows
    return List.generate(specs.length, (index) {
      final entry = specs[index];
      final isEven = index % 2 == 0;
      final isLast = index == specs.length - 1;

      return Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: isEven
              ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
              : theme.colorScheme.onPrimary.withValues(alpha: 0.3),
          border: isLast
              ? Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                  left: BorderSide(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                  right: BorderSide(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                )
              : Border(
                  top: BorderSide(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                  left: BorderSide(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                  right: BorderSide(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label column
            SizedBox(
              width: 140.w,
              child: Text(
                entry.key,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),

            SizedBox(width: 16.w),

            // Value column
            Expanded(
              child: Text(
                entry.value,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: valueColor,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget variantWidget({
    required String label,
    required String variantType,
    required SwatchValues? selectedValue,
    required Function(SwatchValues) onSelected,
    required List<SwatchValues> productAttributes,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$label: ',
                style: TextStyle(
                  fontSize: isTablet(context) ? 20 : 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.8),
                ),
              ),
              Text(
                selectedValue?.value ?? '',
                style: TextStyle(
                  fontSize: isTablet(context) ? 20 : 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.6),
                ),
              )
            ],
          ),
          SizedBox(height: 10.h),
          SizedBox(
            height: variantType == 'color' ? 35.h : 25.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: productAttributes.length,
              itemBuilder: (BuildContext context, int index) {
                final currentValue = productAttributes[index];
                final isSelected = selectedValue == currentValue;
                final color = getColorFromHex(currentValue.swatch);
                return GestureDetector(
                  onTap: () => onSelected(currentValue),
                  child: Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: variantType == 'color'
                        ? Container(
                            width: 35.w,
                            height: 45.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Theme.of(context).colorScheme.outline,
                                width: 1,
                              ),
                            ),
                          )
                        : Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 15,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Theme.of(context).colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              currentValue.value,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildQAItem({
    required String question,
    required String answer,
  }) {
    return Container(
      width: 250.w,
      height: 135.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Question Section (Top Partition)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainer
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(11.r),
                topRight: Radius.circular(11.r),
              ),
            ),
            child: Text(
              question,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                height: 1.3,
              ),
            ),
          ),
          // Divider
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w300,
                  height: 1.4,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sellerStoreName({
    required String storeName,
    required String storeSlug,
    required String sellerName,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        GoRouter.of(context).push(
          AppRoutes.nearbyStoreDetails,
          extra: {
            'store-slug': storeSlug,
            'store-name': storeName,
          },
        );
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0.r),
        ),
        margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 0.h),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.soldBy} ',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isTablet(context) ? 20 : 14.sp,
                ),
              ),
              Expanded(
                child: Text(
                  storeName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: isTablet(context) ? 20 : 14.sp,
                  ),
                ),
              ),
              Directionality.of(context) == TextDirection.ltr
                  ? const Icon(TablerIcons.chevron_right, color: Colors.grey)
                  : const Icon(TablerIcons.chevron_left, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDeliveryBadge(bool available) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: available ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: available ? const Color(0xFFC8E6C9) : const Color(0xFFE0E0E0),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            available ? Icons.bolt_rounded : Icons.local_shipping_rounded,
            color:
                available ? const Color(0xFF2E7D32) : const Color(0xFF757575),
            size: 16.sp,
          ),
          SizedBox(width: 4.w),
          Text(
            available ? "Quick Delivery" : "Standard Delivery",
            style: TextStyle(
              color:
                  available ? const Color(0xFF2E7D32) : const Color(0xFF757575),
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}

class RatingBarWidget extends StatelessWidget {
  final int score;
  final double percentage;
  const RatingBarWidget(
      {required this.score, required this.percentage, super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$score',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${percentage.toInt()}%',
          style: TextStyle(
              color: Theme.of(context).colorScheme.tertiary, fontSize: 14),
        ),
      ],
    );
  }
}

class ProductInitialData {
  final String title;
  final String mainImage;
  final String? heroTag;
  final List<String> additionalImages;
  final String videoUrl;

  ProductInitialData({
    required this.title,
    required this.mainImage,
    this.heroTag,
    this.additionalImages = const [],
    this.videoUrl = '',
  });
}
