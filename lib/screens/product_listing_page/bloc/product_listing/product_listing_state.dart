part of 'product_listing_bloc.dart';

abstract class ProductListingState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductListingInitial extends ProductListingState {}

class ProductListingLoading extends ProductListingState {}

class ProductListingLoaded extends ProductListingState {
  final String message;
  final List<ProductData> productList;
  final List<ProductData> fullProductList; // New: store all products fetched for current page
  final bool hasReachedMax;
  final bool isFilterLoading;
  final SortType currentSortType;
  final int totalProducts;
  final bool isLoading;
  final List<dynamic>? keywords;
  final String? categoryIds;
  final String? brandIds;
  final List<BrandsData>? brandsList;
  final int? appliedDeliveryMinutes; // New: for UI state tracking
  final bool quickDeliveryOnly;

  ProductListingLoaded({
    required this.message,
    required this.productList,
    this.fullProductList = const [],
    required this.hasReachedMax,
    this.isFilterLoading = false,
    required this.isLoading,
    this.currentSortType = SortType.relevance,
    required this.totalProducts,
    this.keywords,
    this.categoryIds,
    this.brandIds,
    this.brandsList,
    this.appliedDeliveryMinutes,
    this.quickDeliveryOnly = false,
  });

  @override
  List<Object?> get props => [
    message,
    productList,
    fullProductList,
    hasReachedMax,
    isFilterLoading,
    currentSortType,
    totalProducts,
    isLoading,
    keywords,
    categoryIds,
    brandIds,
    brandsList,
    appliedDeliveryMinutes,
    quickDeliveryOnly,
  ];

  ProductListingLoaded copyWith({
    String? message,
    List<ProductData>? productList,
    List<ProductData>? fullProductList,
    bool? hasReachedMax,
    bool? isFilterLoading,
    SortType? currentSortType,
    int? totalProducts,
    bool? isLoading,
    List<dynamic>? keywords,
    String? categoryIds,
    String? brandIds,
    List<BrandsData>? brandsList,
    int? appliedDeliveryMinutes,
    bool? quickDeliveryOnly,
  }) {
    return ProductListingLoaded(
      message: message ?? this.message,
      productList: productList ?? this.productList,
      fullProductList: fullProductList ?? this.fullProductList,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isFilterLoading: isFilterLoading ?? this.isFilterLoading,
      currentSortType: currentSortType ?? this.currentSortType,
      totalProducts: totalProducts ?? this.totalProducts,
      isLoading: isLoading ?? this.isLoading,
      keywords: keywords ?? this.keywords,
      categoryIds: categoryIds ?? this.categoryIds,
      brandIds: brandIds ?? this.brandIds,
      brandsList: brandsList ?? this.brandsList,
      appliedDeliveryMinutes: appliedDeliveryMinutes ?? this.appliedDeliveryMinutes,
      quickDeliveryOnly: quickDeliveryOnly ?? this.quickDeliveryOnly,
    );
  }
}

class ProductListingFailed extends ProductListingState {
  final String error;
  ProductListingFailed({required this.error});

  @override
  List<Object?> get props => [error];
}