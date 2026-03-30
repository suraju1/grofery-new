import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchSubCategories();
    _scrollController.addListener(_onScroll);
  }

  void _fetchSubCategories() {
    if (widget.type == ProductListingType.category) {
       context.read<SubCategoryBloc>().add(FetchSubCategory(slug: widget.identifier, isForAllCategory: false));
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
    ));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductListingBloc>().add(FetchMoreListingProducts(
        identifier: widget.identifier,
        type: widget.type,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(color: Colors.black, fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                Text(
                   "${widget.totalProduct} items",
                   style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => _showSortBottomSheet(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                   Icon(Icons.swap_vert, size: 20.sp, color: Colors.black),
                   SizedBox(width: 4.w),
                   Text(
                     "Sort",
                     style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.black),
                   ),
                   SizedBox(width: 4.w),
                   Icon(Icons.keyboard_arrow_down, size: 20.sp, color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatPrice(double price) {
    if (price == price.toInt()) {
      return price.toInt().toString();
    }
    return price.toStringAsFixed(2);
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
                      child: Icon(Icons.close, size: 24.sp, color: Colors.grey[600]),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Sort by",
                        style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  const Divider(),
                  ...SortOption.sortOptions.map((option) {
                    final isSelected = (_selectedSortApiValue ?? 'relevance') == option.apiValue;
                    return RadioListTile<String>(
                      value: option.apiValue,
                      groupValue: _selectedSortApiValue ?? 'relevance',
                      title: Text(
                        option.displayName,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF008000) : Colors.grey[800],
                        ),
                      ),
                      activeColor: const Color(0xFF008000),
                      onChanged: (value) {
                         setModalState(() {
                            _selectedSortApiValue = value;
                         });
                         Navigator.pop(context);
                         context.read<ProductListingBloc>().add(FetchSortedListingProducts(
                           type: widget.type,
                           identifier: _selectedSubCategorySlug ?? widget.identifier,
                           sortType: value!,
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
        color: Colors.grey[50],
        border: Border(right: BorderSide(color: Colors.grey[200]!)),
      ),
      child: BlocBuilder<SubCategoryBloc, SubCategoryState>(
        builder: (context, state) {
          if (state is SubCategoryLoading) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (state is SubCategoryLoaded) {
            final categories = [
              SubCategoryData(id: -1, title: "All", slug: widget.identifier, image: widget.logo),
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
           ));
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          border: isSelected ? Border(left: BorderSide(color: Colors.green, width: 4.w)) : null,
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
                boxShadow: isSelected ? [BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 8, spreadRadius: 2)] : null,
              ),
              child: ClipOval(
                child: category.id == -1
                  ? Icon(Icons.shopping_basket, color: isSelected ? Colors.green : Colors.blue, size: 24.sp)
                  : (category.image != null 
                     ? CachedNetworkImage(imageUrl: category.image!, fit: BoxFit.cover)
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
          return const Center(child: CircularProgressIndicator());
        } else if (state is ProductListingLoaded) {
          if (state.productList.isEmpty) {
            return const Center(child: Text("No products found"));
          }
          return ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.only(bottom: 20.h),
            itemCount: state.productList.length + (state.hasReachedMax ? 0 : 1),
            itemBuilder: (context, index) {
              if (index >= state.productList.length) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ));
              }
              final product = state.productList[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                child: CustomProductCard(
                  productId: product.id,
                  productImage: product.mainImage,
                  productName: product.title,
                  productSlug: product.slug,
                  productPrice: product.variants.first.price.toString(),
                  productTags: product.tags,
                  specialPrice: product.variants.first.specialPrice.toString(),
                  estimatedDeliveryTime: product.estimatedDeliveryTime,
                  ratings: product.ratings.toDouble(),
                  ratingCount: product.ratingCount,
                  onAddToCart: (qty) {},
                  isStoreOpen: product.storeStatus?.isOpen ?? true,
                  isWishListed: product.favorite != null && product.favorite!.isNotEmpty,
                  productVariantId: product.variants.first.id,
                  storeId: product.variants.first.storeId,
                  wishlistItemId: product.favorite?.first.id ?? 0,
                  totalStocks: product.variants.first.stock,
                  imageFit: product.imageFit,
                  quantityStepSize: product.quantityStepSize,
                  minQty: product.minimumOrderQuantity,
                  totalAllowedQuantity: product.totalAllowedQuantity,
                  tieredPricing: product.variants.first.tieredPricing,
                  useHorizontalLayout: true, // Switched to horizontal
                ),
              );
            },
          );
        } else if (state is ProductListingFailed) {
          return Center(child: Text(state.error));
        }
        return const SizedBox.shrink();
      },
    );
  }
}
