import 'package:flutter/material.dart';
import '../../../utils/widgets/custom_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../model/sorting_model/sorting_model.dart';
import '../../../utils/widgets/custom_product_card.dart';
import '../../home_page/bloc/sub_category/sub_category_bloc.dart';
import '../../home_page/bloc/sub_category/sub_category_event.dart';
import '../../home_page/bloc/sub_category/sub_category_state.dart';
import '../../home_page/model/sub_category_model.dart';
import '../bloc/product_listing/product_listing_bloc.dart';
import '../model/product_listing_type.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../model/user_cart_model/user_cart.dart';
import '../../../model/user_cart_model/cart_sync_action.dart';
import '../../../utils/widgets/custom_shimmer.dart';
import '../../../utils/widgets/custom_refresh_indicator.dart';
import 'package:go_router/go_router.dart';
import '../../../router/app_routes.dart';


class ProductListingPage extends StatefulWidget {
  final bool isTheirMoreCategory;
  final String title;
  final String logo;
  final String totalProduct;
  final ProductListingType type;
  final String identifier;

  const ProductListingPage({
    super.key,
    required this.isTheirMoreCategory,
    required this.title,
    required this.logo,
    required this.totalProduct,
    required this.type,
    required this.identifier,
  });

  @override
  State<ProductListingPage> createState() => _ProductListingPageState();
}

class _ProductListingPageState extends State<ProductListingPage> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedSubCategorySlug;
  String? _selectedSortApiValue;
  bool _isRated4Plus = false;
  String? _selectedIndicator; // 'veg', 'non_veg'
  final List<String> _selectedBrandSlugs = [];
  int? _selectedMaxDeliveryMinutes;
  int? _selectedMinDeliveryMinutes;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchSubCategories();
    _scrollController.addListener(_onScroll);
  }

  void _fetchSubCategories() {
    if (widget.type == ProductListingType.category) {
      context.read<SubCategoryBloc>().add(
          FetchSubCategory(slug: widget.identifier, isForAllCategory: false));
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchProducts() {
    context.read<ProductListingBloc>().add(FetchListingProducts(
          type: widget.type,
          identifier: widget.identifier,
          indicator: _selectedIndicator,
          rating: _isRated4Plus ? 4.0 : null,
          brandSlugs: _selectedBrandSlugs,
        ));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductListingBloc>().add(FetchMoreListingProducts(
            identifier: _selectedSubCategorySlug ?? widget.identifier,
            type: widget.type,
            indicator: _selectedIndicator,
            rating: _isRated4Plus ? 4.0 : null,
          ));
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            if (widget.logo.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: widget.logo,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            BlocBuilder<ProductListingBloc, ProductListingState>(
              builder: (context, state) {
                String count = widget.totalProduct;
                if (state is ProductListingLoaded) {
                  count = state.totalProducts.toString();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "$count items",
                      style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () => context.push(AppRoutes.search),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(),
                Expanded(child: _buildProductList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            _buildFilterChip(
              onTap: () => _showSortBottomSheet(),
              icon: Icons.swap_vert,
              label: "Sort",
              showDropdown: true,
              isSelected: _selectedSortApiValue != null &&
                  _selectedSortApiValue != 'relevance',
            ),
            SizedBox(width: 8.w),
            _buildFilterChip(
              onTap: () {
                setState(() => _isRated4Plus = !_isRated4Plus);
                _applyFilters();
              },
              icon: Icons.star,
              iconColor: Colors.orange,
              label: "Rated 4.0+",
              isSelected: _isRated4Plus,
            ),
            SizedBox(width: 8.w),
            _buildFilterChip(
              onTap: () {
                setState(() => _selectedIndicator =
                    (_selectedIndicator == 'veg' ? null : 'veg'));
                _applyFilters();
              },
              icon: Icons.circle,
              iconColor: Colors.green,
              isIndicator: true,
              label: "Veg",
              isSelected: _selectedIndicator == 'veg',
            ),
            SizedBox(width: 8.w),
            _buildFilterChip(
              onTap: () {
                setState(() => _selectedIndicator =
                    (_selectedIndicator == 'non_veg' ? null : 'non_veg'));
                _applyFilters();
              },
              icon: Icons.circle,
              iconColor: Colors.red,
              isIndicator: true,
              label: "Non-Veg",
              isSelected: _selectedIndicator == 'non_veg',
            ),
            SizedBox(width: 8.w),
            _buildFilterChip(
              onTap: () {
                setState(() {
                  if (_selectedMaxDeliveryMinutes == 30 &&
                      _selectedMinDeliveryMinutes == null) {
                    _selectedMaxDeliveryMinutes = null;
                    _selectedMinDeliveryMinutes = null;
                  } else {
                    _selectedMaxDeliveryMinutes = 30;
                    _selectedMinDeliveryMinutes = null;
                  }
                });
                context.read<ProductListingBloc>().add(FilterByDeliveryTime(
                    maxMinutes: _selectedMaxDeliveryMinutes,
                    minMinutes: _selectedMinDeliveryMinutes));
              },
              label: "⚡ Fast Delivery",
              isSelected: _selectedMaxDeliveryMinutes == 30 &&
                  _selectedMinDeliveryMinutes == null,
            ),
            SizedBox(width: 8.w),
            _buildFilterChip(
              onTap: () => _showBrandBottomSheet(),
              label: "Brand",
              showDropdown: true,
              isSelected: _selectedBrandSlugs.isNotEmpty,
            ),
          ],
        ),
      ),
    );
  }

  void _applyFilters() {
    context.read<ProductListingBloc>().add(FetchFilteredListingProducts(
          type: widget.type,
          identifier: _selectedSubCategorySlug ?? widget.identifier,
          categorySlugs: [], // TODO: categories if needed
          brandSlugs: _selectedBrandSlugs,
          indicator: _selectedIndicator,
          rating: _isRated4Plus ? 4.0 : null,
        ));
  }

  Widget _buildFilterChip({
    VoidCallback? onTap,
    IconData? icon,
    Color? iconColor,
    required String label,
    bool showDropdown = false,
    bool isIndicator = false,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
            border: Border.all(
                color: isSelected ? Colors.green : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 2,
                offset: const Offset(0, 1),
              )
            ]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              if (isIndicator)
                Container(
                  width: 14.sp,
                  height: 14.sp,
                  padding: EdgeInsets.all(2.sp),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: iconColor ?? Colors.black, width: 1.5),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              else
                Icon(icon, size: 16.sp, color: iconColor ?? Colors.black),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (showDropdown) ...[
              SizedBox(width: 4.w),
              Icon(Icons.keyboard_arrow_down,
                  size: 16.sp, color: Colors.black87),
            ],
          ],
        ),
      ),
    );
  }

  String formatPrice(double price) {
    if (price == price.toInt()) {
      return price.toInt().toString();
    }
    return price.toStringAsFixed(2);
  }

  void _showBrandBottomSheet() {
    final currentState = context.read<ProductListingBloc>().state;
    if (currentState is! ProductListingLoaded ||
        currentState.brandsList == null ||
        currentState.brandsList!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No brands available for this category")),
      );
      return;
    }

    final brands = currentState.brandsList!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 12.h),
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Select Brands",
                          style: TextStyle(
                              fontSize: 20.sp, fontWeight: FontWeight.bold),
                        ),
                        if (_selectedBrandSlugs.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setModalState(() => _selectedBrandSlugs.clear());
                            },
                            child: const Text("Clear all"),
                          ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: brands.length,
                      itemBuilder: (context, index) {
                        final brand = brands[index];
                        final isSelected =
                            _selectedBrandSlugs.contains(brand.slug);
                        return CheckboxListTile(
                          value: isSelected,
                          title: Text(brand.title ?? "Unknown Brand"),
                          activeColor: Colors.green,
                          onChanged: (bool? value) {
                            setModalState(() {
                              if (value == true) {
                                _selectedBrandSlugs.add(brand.slug!);
                              } else {
                                _selectedBrandSlugs.remove(brand.slug!);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _applyFilters();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: Size(double.infinity, 50.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                      ),
                      child: Text("Apply Filters",
                          style:
                              TextStyle(fontSize: 16.sp, color: Colors.white)),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 12.h),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close,
                          size: 24.sp, color: Colors.grey[600]),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Sort by",
                        style: TextStyle(
                            fontSize: 22.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  const Divider(),
                  ...SortOption.sortOptions.map((option) {
                    final isSelected = (_selectedSortApiValue ?? 'relevance') ==
                        option.apiValue;
                    return RadioListTile<String>(
                      value: option.apiValue,
                      groupValue: _selectedSortApiValue ?? 'relevance',
                      title: Text(
                        option.displayName,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFF008000)
                              : Colors.grey[800],
                        ),
                      ),
                      activeColor: const Color(0xFF008000),
                      onChanged: (value) {
                        setModalState(() {
                          _selectedSortApiValue = value;
                        });
                        Navigator.pop(context);
                        context
                            .read<ProductListingBloc>()
                            .add(FetchSortedListingProducts(
                              type: widget.type,
                              identifier:
                                  _selectedSubCategorySlug ?? widget.identifier,
                              sortType: value!,
                              indicator: _selectedIndicator,
                              rating: _isRated4Plus ? 4.0 : null,
                            ));
                      },
                    );
                  }),
                  SizedBox(height: 20.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 80.w,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[200]!)),
      ),
      child: BlocBuilder<SubCategoryBloc, SubCategoryState>(
        builder: (context, state) {
          if (state is SubCategoryLoading) {
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (state is SubCategoryLoaded) {
            final categories = [
              SubCategoryData(
                  id: -1,
                  title: "All",
                  slug: widget.identifier,
                  image: widget.logo),
              ...state.subCategoryData,
            ];
            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final bool isSelected = _selectedSubCategorySlug == null
                    ? (index == 0)
                    : (category.slug == _selectedSubCategorySlug);
                return _buildSidebarItem(category, isSelected);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSidebarItem(SubCategoryData category, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSubCategorySlug = category.slug;
        });
        if (category.id == -1) {
          // Show All
          _fetchProducts();
        } else {
          // Filter by subcategory
          context.read<ProductListingBloc>().add(FetchListingProducts(
                type: ProductListingType.category,
                identifier: category.slug ?? "",
                indicator: _selectedIndicator,
                rating: _isRated4Plus ? 4.0 : null,
                brandSlugs: _selectedBrandSlugs,
              ));
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          border: isSelected
              ? Border(right: BorderSide(color: Colors.green, width: 4.w))
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: Colors.green.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 2)
                      ]
                    : null,
              ),
              child: ClipOval(
                child: category.id == -1
                    ? Icon(Icons.shopping_basket,
                        color: isSelected ? Colors.green : Colors.blue,
                        size: 24.sp)
                    : (category.image != null
                        ? CachedNetworkImage(
                            imageUrl: category.image!, fit: BoxFit.cover)
                        : const Icon(Icons.category)),
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                category.title ?? "",
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isSelected ? Colors.green[800] : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return BlocBuilder<ProductListingBloc, ProductListingState>(
      builder: (context, state) {
        if (state is ProductListingLoading) {
          return _buildShimmerList();
        } else if (state is ProductListingLoaded) {
          final filteredProducts = state.productList;

          return CustomRefreshIndicator(
            onRefresh: () async {
              _fetchProducts();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: state.isFilterLoading
                  ? _buildShimmerList(key: const ValueKey('shimmer'))
                  : (filteredProducts.isEmpty
                      ? const Center(
                          key: ValueKey('no_products'),
                          child: Text("No products found"))
                      : ListView.builder(
                          key: ValueKey('product_list_${filteredProducts.length}'),
                          controller: _scrollController,
                          padding: EdgeInsets.only(bottom: 20.h),
                          itemCount: filteredProducts.length +
                              (state.hasReachedMax ? 0 : 1),
                          itemBuilder: (context, index) {
                            if (index >= filteredProducts.length) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                child: _buildShimmerItem(), // Use shimmer item for pagination too
                              );
                            }
                            final product = filteredProducts[index];
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 4.h),
                              child: CustomProductCard(
                                productId: product.id,
                                productImage: product.mainImage,
                                productName: product.title,
                                productSlug: product.slug,
                                productPrice:
                                    product.variants.first.price.toString(),
                                productTags: product.tags,
                                specialPrice: product.variants.first.specialPrice
                                    .toString(),
                                estimatedDeliveryTime:
                                    product.estimatedDeliveryTime,
                                ratings: product.ratings.toDouble(),
                                ratingCount: product.ratingCount,
                                onAddToCart: (qty) {
                                  final variant = product.variants.first;
                                  context.read<CartBloc>().add(
                                        AddToCart(
                                          context: context,
                                          item: UserCart(
                                            productId: product.id.toString(),
                                            variantId: variant.id.toString(),
                                            variantName: variant.title,
                                            vendorId: variant.storeId.toString(),
                                            name: product.title,
                                            image: product.mainImage,
                                            price: variant.getEffectivePrice(qty),
                                            originalPrice:
                                                variant.price.toDouble(),
                                            quantity: qty,
                                            minQty: product.minimumOrderQuantity,
                                            maxQty: product.totalAllowedQuantity,
                                            isOutOfStock: variant.stock <= 0,
                                            isSynced: false,
                                            updatedAt: DateTime.now(),
                                            syncAction: CartSyncAction.add,
                                            tieredPricing: variant.tieredPricing,
                                          ),
                                        ),
                                      );
                                },
                                isStoreOpen: product.storeStatus?.isOpen ?? true,
                                isWishListed: product.favorite != null &&
                                    product.favorite!
                                        .any((f) => f.wishlistId == 1),
                                productVariantId: product.variants.first.id,
                                storeId: product.variants.first.storeId,
                                wishlistItemId: (product.favorite?.any(
                                            (f) => f.wishlistId == 1) ??
                                        false)
                                    ? product.favorite!
                                            .firstWhere((f) => f.wishlistId == 1)
                                            .id ??
                                        0
                                    : 0,
                                totalStocks: product.variants.first.stock,
                                imageFit: product.imageFit,
                                quantityStepSize: product.quantityStepSize,
                                minQty: product.minimumOrderQuantity,
                                totalAllowedQuantity:
                                    product.totalAllowedQuantity,
                                tieredPricing:
                                    product.variants.first.tieredPricing,
                                indicator: product.indicator,
                                useHorizontalLayout: true,
                              ),
                            );
                          },
                        )),
            ),
          );
        } else if (state is ProductListingFailed) {
          return Center(child: Text(state.error));
        }
        return const SizedBox.shrink();
      },
    );
  }
  Widget _buildShimmerList({Key? key}) {
    return ListView.builder(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      itemCount: 6,
      itemBuilder: (context, index) => _buildShimmerItem(),
    );
  }

  Widget _buildShimmerItem() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      child: Container(
        height: 180.h,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          ShimmerWidget.rectangular(
            isBorder: true,
            height: 12.h,
            width: 80.w,
            borderRadius: 4,
          ),
          SizedBox(height: 12.h),
          ShimmerWidget.rectangular(
            isBorder: true,
            height: 18.h,
            width: 150.w,
            borderRadius: 4,
          ),
          SizedBox(height: 8.h),
          ShimmerWidget.rectangular(
            isBorder: true,
            height: 14.h,
            width: 60.w,
            borderRadius: 4,
          ),
          const Spacer(),
          Row(
            children: [
              ShimmerWidget.rectangular(
                isBorder: true,
                height: 20.h,
                width: 60.w,
                borderRadius: 4,
              ),
              SizedBox(width: 8.w),
              ShimmerWidget.rectangular(
                isBorder: true,
                height: 14.h,
                width: 40.w,
                borderRadius: 4,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              ShimmerWidget.rectangular(
                isBorder: true,
                height: 32.h,
                width: 70.w,
                borderRadius: 8,
              ),
            ],
          ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            ShimmerWidget.rectangular(
              isBorder: true,
              height: 100.w,
              width: 100.w,
              borderRadius: 12.r,
            ),
          ],
        ),
      ),
    );
  }
}
