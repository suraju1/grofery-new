import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grofery_user/screens/home_page/model/brands_model.dart';
import 'package:grofery_user/screens/product_detail_page/model/product_detail_model.dart';
//
import '../../../../model/sorting_model/sorting_model.dart';
import '../../../../services/location/location_service.dart';
import '../../repo/category_product_repo.dart';
import '../../model/product_listing_type.dart';

part 'product_listing_event.dart';
part 'product_listing_state.dart';

class ProductListingBloc
    extends Bloc<ProductListingEvent, ProductListingState> {
  ProductListingBloc() : super(ProductListingInitial()) {
    log('Initializing ProductListingBloc with FilterByDeliveryTime handler');
    on<FetchListingProducts>(_onFetchListingProducts);
    on<FetchMoreListingProducts>(_onFetchMoreListingProducts);
    on<FetchSortedListingProducts>(_onFetchSortedListingProducts);
    on<ResetSearchKeywords>(_onResetSearchKeywords);
    on<FetchFilteredListingProducts>(_onFetchFilteredListingProducts);
    on<ApplyFiltersAndSort>(_onApplyFiltersAndSort);
    on<ClearProductFilters>(_onClearProductFilters);
    on<FilterByDeliveryTime>((event, emit) => _onFilterByDeliveryTime(event, emit));
  }

  int currentPage = 1;
  int perPage = 15;
  int? lastPage;
  bool hasReachedMax = false;
  bool isLoadingMore = false;
  final CategoryProductRepository repository = CategoryProductRepository();
  SortType currentSortType = SortType.relevance;
  int totalProducts = 0;
  ProductListingType type = ProductListingType.search;
  String selectedSortingType = '';

  List<String> appliedCategorySlugs = [];
  List<String> appliedBrandSlugs = [];
  String? appliedIndicator;
  double? appliedRating;

  // Frontend-only filter tracking
  int? appliedMaxDeliveryMinutes;
  int? appliedMinDeliveryMinutes;

  Future<void> _onFetchListingProducts(
      FetchListingProducts event, Emitter<ProductListingState> emit) async {
    emit(ProductListingLoading());
    try {
      final location = LocationService.getStoredLocation();
      if (location == null) {
        emit(ProductListingFailed(error: 'Location not found. Please select a delivery location.'));
        return;
      }

      appliedCategorySlugs = event.categorySlugs ?? [];
      appliedBrandSlugs = event.brandSlugs ?? [];
      appliedIndicator = event.indicator;
      appliedRating = event.rating;
      currentPage = 1;
      hasReachedMax = false;
      isLoadingMore = false;
      currentSortType = SortType.relevance;
      List<dynamic> keywords = [];
      String? categoryIds = '';
      String? brandIds = '';
      type = event.type;
      totalProducts = 0;
      selectedSortingType = event.sortType ?? 'default';

      final response = await repository.fetchProductsByType(
          type: event.type,
          identifier: event.identifier,
          sortType: selectedSortingType,
          currentPage: currentPage,
          perPage: perPage,
          isSearchInStore: event.isSearchInStore ?? false,
          storeSlug: event.storeSlug ?? '',
          includeChildCategories: event.includeChildCategories,
          categorySlugs: appliedCategorySlugs,
          brandSlugs: appliedBrandSlugs,
          indicator: appliedIndicator,
          rating: appliedRating);

      final dynamic responseData = response['data'];

      if (responseData != null && 
          ((responseData is Map && (responseData['data'] != null || responseData['products'] != null)) || 
           (responseData is List && responseData.isNotEmpty))) {
        
        List<dynamic> rawList = [];
        if (responseData is Map) {
          rawList = (responseData['data'] ?? responseData['products'] ?? []) as List<dynamic>;
          totalProducts = int.tryParse((responseData['total'] ?? responseData['products_count'] ?? rawList.length).toString()) ?? 0;
          final int currentPageNum = int.tryParse(responseData['current_page'].toString()) ?? 1;
          final int lastPageNum = int.tryParse(responseData['last_page'].toString()) ?? 1;
          hasReachedMax = currentPageNum >= lastPageNum;
          
          if (event.type == ProductListingType.search && responseData['keywords'] != null) {
            keywords = responseData['keywords'] as List<dynamic>;
          }
        } else {
          rawList = responseData;
          totalProducts = rawList.length;
          hasReachedMax = true; // Non-paginated list is usually complete
        }

        var products = List<ProductData>.from(
            rawList.map((data) => ProductData.fromJson(data)));

        if (appliedIndicator != null && appliedIndicator!.isNotEmpty) {
          products = products.where((p) => p.indicator == appliedIndicator).toList();
        }
        if (appliedRating != null) {
          products = products.where((p) => p.ratings >= appliedRating!).toList();
        }

        List<BrandsData> brandsList = [];
        if (responseData is Map && responseData['brands'] != null) {
          brandsList = List<BrandsData>.from(
              responseData['brands'].map((v) => BrandsData.fromJson(v)));
        }
        
        if (brandsList.isEmpty) {
          brandsList = _extractBrandsFromProducts(rawList);
        }

        if (response['success'] == true) {
          emit(ProductListingLoaded(
              message: response['message'],
              productList: _applyFrontendFilters(products),
              fullProductList: products,
              hasReachedMax: hasReachedMax,
              isFilterLoading: false,
              isLoading: false,
              currentSortType: currentSortType,
              totalProducts: totalProducts,
              keywords: keywords,
              categoryIds: categoryIds,
              brandIds: brandIds,
              brandsList: brandsList,
              appliedDeliveryMinutes: appliedMaxDeliveryMinutes));
        } else {
          emit(ProductListingFailed(error: response['message']));
        }
      } else {
        emit(ProductListingFailed(
            error: response['message'] ?? 'No products found'));
      }
    } catch (e, err) {
      log('Error in ProductListingBloc: $e\n$err');
      emit(ProductListingFailed(error: 'Something went wrong while loading products.'));
    }
  }

  Future<void> _onFetchMoreListingProducts(
      FetchMoreListingProducts event, Emitter<ProductListingState> emit) async {
    final currentState = state;
    if (currentState is ProductListingLoaded) {
      if (hasReachedMax || isLoadingMore) return;

      isLoadingMore = true;
      // Emit loading state so UI can show the bottom loader
      emit(currentState.copyWith(isLoading: true));

      try {
        currentPage += 1;
        List<dynamic> keywords = [];
        String? categoryIds = '';
        String? brandIds = '';

        final response = await repository.fetchProductsByType(
            type: type,
            identifier: event.identifier,
            sortType: selectedSortingType,
            currentPage: currentPage,
            perPage: perPage,
            isSearchInStore: event.isSearchInStore ?? false,
            storeSlug: event.storeSlug ?? '',
            categorySlugs: appliedCategorySlugs,
            brandSlugs: appliedBrandSlugs,
            indicator: appliedIndicator,
            rating: appliedRating);

        final dynamic responseData = response['data'];

        if (responseData != null && 
            ((responseData is Map && (responseData['data'] != null || responseData['products'] != null)) || 
             (responseData is List && responseData.isNotEmpty))) {
          
          List<dynamic> rawList = [];
          if (responseData is Map) {
            rawList = (responseData['data'] ?? responseData['products'] ?? []) as List<dynamic>;
            final int currentPageNum = int.tryParse(responseData['current_page'].toString()) ?? currentPage;
            final int lastPageNum = int.tryParse(responseData['last_page'].toString()) ?? currentPage;
            hasReachedMax = currentPageNum >= lastPageNum;
          } else {
            rawList = responseData;
            hasReachedMax = true;
          }

          var newProducts = List<ProductData>.from(
              rawList.map((data) => ProductData.fromJson(data)));

          if (appliedIndicator != null && appliedIndicator!.isNotEmpty) {
            newProducts = newProducts.where((p) => p.indicator == appliedIndicator).toList();
          }
          if (appliedRating != null) {
            newProducts = newProducts.where((p) => p.ratings >= appliedRating!).toList();
          }
          if (event.type == ProductListingType.search) {
            keywords = response['data']['keywords'];
          }
          // Correct hasReachedMax: check if current_page >= last_page
          final int currentPageNum =
              int.tryParse(response['data']['current_page'].toString()) ??
                  currentPage;
          final int lastPageNum =
              int.tryParse(response['data']['last_page'].toString()) ??
                  currentPage;
          hasReachedMax = currentPageNum >= lastPageNum;
          /*categoryIds = response['data']['category_ids'] as String;
          brandIds = response['data']['brand_ids'] as String;*/

          List<BrandsData> brandsList = currentState.brandsList ?? [];
          if (response['data']['brands'] != null) {
            brandsList = List<BrandsData>.from(
                response['data']['brands'].map((v) => BrandsData.fromJson(v)));
          }
          // Fallback: extract from product data if no brands list returned
          if (brandsList.isEmpty) {
            brandsList = _extractBrandsFromProducts(
                response['data']['data'] as List<dynamic>);
          }

          // ✅ Remove duplicates when combining lists
          final updatedProductList =
              List<ProductData>.from(currentState.productList);

          // Add only unique products
          for (final newProduct in newProducts) {
            if (!updatedProductList
                .any((existing) => existing.id == newProduct.id)) {
              updatedProductList.add(newProduct);
            }
          }

          emit(ProductListingLoaded(
              message: response['message'],
              productList: _applyFrontendFilters(updatedProductList),
              fullProductList: updatedProductList,
              hasReachedMax: hasReachedMax,
              isFilterLoading: false,
              isLoading: false,
              currentSortType: currentSortType,
              totalProducts: totalProducts,
              keywords: keywords,
              categoryIds: categoryIds,
              brandIds: brandIds,
              brandsList: brandsList,
              appliedDeliveryMinutes: appliedMaxDeliveryMinutes));
        } else {
          emit(ProductListingFailed(
              error: response['message'] ?? 'No products found'));
        }
      } catch (e) {
        // ✅ Reset page on error
        currentPage -= 1;
        emit(ProductListingFailed(error: e.toString()));
      } finally {
        isLoadingMore = false;
      }
    }
  }

  Future<void> _onFetchSortedListingProducts(FetchSortedListingProducts event,
      Emitter<ProductListingState> emit) async {
    final currentState = state;
    if (currentState is ProductListingLoaded) {
      emit(currentState.copyWith(isFilterLoading: true));
    }

    try {
      // ✅ Reset pagination for sorting
      currentPage = 1;
      hasReachedMax = false;
      isLoadingMore = false;
      List<dynamic> keywords = [];
      String? categoryIds = '';
      String? brandIds = '';
      selectedSortingType = event.sortType;

      final response = await repository.fetchProductsByType(
          type: type,
          identifier: event.identifier,
          sortType: event.sortType,
          currentPage: currentPage,
          perPage: perPage,
          isSearchInStore: event.isSearchInStore ?? false,
          storeSlug: event.storeSlug ?? '',
          categorySlugs: appliedCategorySlugs,
          brandSlugs: appliedBrandSlugs,
          indicator: appliedIndicator,
          rating: appliedRating);

      final dynamic responseData = response['data'];

      if (responseData != null && 
          ((responseData is Map && (responseData['data'] != null || responseData['products'] != null)) || 
           (responseData is List && responseData.isNotEmpty))) {
        
        List<dynamic> rawList = [];
        if (responseData is Map) {
          rawList = (responseData['data'] ?? responseData['products'] ?? []) as List<dynamic>;
          totalProducts = int.tryParse((responseData['total'] ?? responseData['products_count'] ?? rawList.length).toString()) ?? 0;
          final int currentPageNum = int.tryParse(responseData['current_page']?.toString() ?? '1') ?? 1;
          final int lastPageNum = int.tryParse(responseData['last_page']?.toString() ?? '1') ?? 1;
          hasReachedMax = currentPageNum >= lastPageNum;
        } else {
          rawList = responseData;
          totalProducts = rawList.length;
          hasReachedMax = true;
        }

        var products = List<ProductData>.from(
            rawList.map((data) => ProductData.fromJson(data)));

        if (appliedIndicator != null && appliedIndicator!.isNotEmpty) {
          products = products.where((p) => p.indicator == appliedIndicator).toList();
        }
        if (appliedRating != null) {
          products = products.where((p) => p.ratings >= appliedRating!).toList();
        }

        List<BrandsData> brandsList = [];
        if (responseData is Map && responseData['brands'] != null) {
          brandsList = List<BrandsData>.from(
              responseData['brands'].map((v) => BrandsData.fromJson(v)));
        }
        
        if (brandsList.isEmpty) {
          brandsList = _extractBrandsFromProducts(rawList);
        }

        currentSortType = SortOption.getSortOptionByApiValue(event.sortType).type;

        if (response['success'] == true) {
          emit(ProductListingLoaded(
              message: response['message'],
              productList: _applyFrontendFilters(products),
              fullProductList: products,
              hasReachedMax: hasReachedMax,
              isFilterLoading: false,
              isLoading: false,
              currentSortType: currentSortType,
              totalProducts: totalProducts,
              keywords: keywords,
              categoryIds: categoryIds,
              brandIds: brandIds,
              brandsList: brandsList,
              appliedDeliveryMinutes: appliedMaxDeliveryMinutes));
        } else {
          emit(ProductListingFailed(error: response['message']));
        }
      } else {
        emit(ProductListingFailed(error: response['message'] ?? 'No products found'));
      }
    } catch (e) {
      log('Error in _onFetchSortedListingProducts: $e');
      emit(ProductListingFailed(error: e.toString()));
    }
  }

  Future<void> _onResetSearchKeywords(
      ResetSearchKeywords event, Emitter<ProductListingState> emit) async {
    emit(ProductListingInitial());
  }

  Future<void> _onFetchFilteredListingProducts(
    FetchFilteredListingProducts event,
    Emitter<ProductListingState> emit,
  ) async {
    final currentState = state;

    // Show loading state while keeping existing products visible
    if (currentState is ProductListingLoaded) {
      emit(ProductListingLoaded(
          message: currentState.message,
          productList: currentState.productList,
          hasReachedMax: false,
          isFilterLoading: true,
          isLoading: false,
          currentSortType: currentState.currentSortType,
          totalProducts: currentState.totalProducts,
          keywords: currentState.keywords,
          categoryIds: currentState.categoryIds,
          brandIds: currentState.brandIds));
    } else {
      emit(ProductListingLoading());
    }

    try {
      currentPage = 1;
      hasReachedMax = false;
      isLoadingMore = false;
      type = event.type;
      selectedSortingType = selectedSortingType;
      appliedCategorySlugs = event.categorySlugs;
      appliedBrandSlugs = event.brandSlugs;
      appliedIndicator = event.indicator;
      appliedRating = event.rating;
      List<dynamic> keywords = [];
      String? categoryIds = '';
      String? brandIds = '';

      final response = await repository.fetchProductsByType(
          type: event.type,
          identifier: event.identifier,
          sortType: selectedSortingType,
          currentPage: currentPage,
          perPage: perPage,
          isSearchInStore: event.isSearchInStore ?? false,
          storeSlug: event.storeSlug ?? '',
          categorySlugs: appliedCategorySlugs,
          brandSlugs: appliedBrandSlugs,
          indicator: appliedIndicator,
          rating: appliedRating);

      final dynamic responseData = response['data'];

      if (responseData != null && 
          ((responseData is Map && (responseData['data'] != null || responseData['products'] != null)) || 
           (responseData is List && responseData.isNotEmpty))) {
        
        List<dynamic> rawList = [];
        if (responseData is Map) {
          rawList = (responseData['data'] ?? responseData['products'] ?? []) as List<dynamic>;
          totalProducts = int.tryParse((responseData['total'] ?? responseData['products_count'] ?? rawList.length).toString()) ?? 0;
          final int currentPageNum = int.tryParse(responseData['current_page']?.toString() ?? '1') ?? 1;
          final int lastPageNum = int.tryParse(responseData['last_page']?.toString() ?? '1') ?? 1;
          hasReachedMax = currentPageNum >= lastPageNum;
          
          if (event.type == ProductListingType.search && responseData['keywords'] != null) {
            keywords = responseData['keywords'] as List<dynamic>;
          }
        } else {
          rawList = responseData;
          totalProducts = rawList.length;
          hasReachedMax = true;
        }

        var products = List<ProductData>.from(
            rawList.map((data) => ProductData.fromJson(data)));

        if (appliedIndicator != null && appliedIndicator!.isNotEmpty) {
          products = products.where((p) => p.indicator == appliedIndicator).toList();
        }
        if (appliedRating != null) {
          products = products.where((p) => p.ratings >= appliedRating!).toList();
        }

        List<BrandsData> brandsList = [];
        if (responseData is Map && responseData['brands'] != null) {
          brandsList = List<BrandsData>.from(
              responseData['brands'].map((v) => BrandsData.fromJson(v)));
        }
        
        if (brandsList.isEmpty) {
          brandsList = _extractBrandsFromProducts(rawList);
        }

        currentSortType = SortOption.getSortOptionByApiValue(selectedSortingType).type;

        if (response['success'] == true) {
          emit(ProductListingLoaded(
              message: response['message'],
              productList: _applyFrontendFilters(products),
              fullProductList: products,
              hasReachedMax: hasReachedMax,
              isFilterLoading: false,
              isLoading: false,
              currentSortType: currentSortType,
              totalProducts: totalProducts,
              keywords: keywords,
              categoryIds: categoryIds,
              brandIds: brandIds,
              brandsList: brandsList,
              appliedDeliveryMinutes: appliedMaxDeliveryMinutes));
        } else {
          emit(ProductListingFailed(error: response['message']));
        }
      } else {
        emit(ProductListingFailed(error: response['message'] ?? 'No products found'));
      }
    } catch (e) {
      log('Error in _onFetchFilteredListingProducts: $e');
      emit(ProductListingFailed(error: e.toString()));
    }
  }

  /// Handler for applying both filters and sorting
  Future<void> _onApplyFiltersAndSort(
    ApplyFiltersAndSort event,
    Emitter<ProductListingState> emit,
  ) async {
    // Reuse the filtered products handler
    add(FetchFilteredListingProducts(
      type: event.type,
      identifier: event.identifier,
      storeSlug: event.storeSlug,
      isSearchInStore: event.isSearchInStore,
      categorySlugs: event.categorySlugs,
      brandSlugs: event.brandSlugs,
      indicator: event.indicator,
      rating: event.rating,
    ));
  }

  /// Handler for clearing filters
  Future<void> _onClearProductFilters(
    ClearProductFilters event,
    Emitter<ProductListingState> emit,
  ) async {
    appliedCategorySlugs.clear();
    appliedBrandSlugs.clear();
    appliedIndicator = null;
    appliedRating = null;

    // Fetch products without filters
    add(FetchListingProducts(
      type: event.type,
      identifier: event.identifier,
      storeSlug: event.storeSlug,
      sortType: selectedSortingType,
      isSearchInStore: event.isSearchInStore,
    ));
  }

  /// Extracts unique brands from product list as fallback when the API
  /// doesn't return a dedicated `brands` array.
  List<BrandsData> _extractBrandsFromProducts(List<dynamic> rawProducts) {
    final seen = <String>{};
    final extracted = <BrandsData>[];
    for (final p in rawProducts) {
      final slug = p['brand'] as String?;
      final name = p['brand_name'] as String?;
      if (slug != null && slug.isNotEmpty && seen.add(slug)) {
        extracted.add(BrandsData(title: name, slug: slug));
      }
    }
    return extracted;
  }

  void _onFilterByDeliveryTime(
    FilterByDeliveryTime event,
    Emitter<ProductListingState> emit,
  ) {
    appliedMaxDeliveryMinutes = event.maxMinutes;
    appliedMinDeliveryMinutes = event.minMinutes;

    final currentState = state;
    if (currentState is ProductListingLoaded) {
      final filteredList = _applyFrontendFilters(currentState.fullProductList);
      emit(currentState.copyWith(
        productList: filteredList,
        appliedDeliveryMinutes: appliedMaxDeliveryMinutes,
      ));
    }
  }

  List<ProductData> _applyFrontendFilters(List<ProductData> products) {
    List<ProductData> result = products;

    if (appliedMaxDeliveryMinutes != null || appliedMinDeliveryMinutes != null) {
      result = result.where((product) {
        final minutes = _parseDeliveryTime(product.estimatedDeliveryTime);
        if (minutes == null) return true; // Keep if we can't parse? or filter out? Usually keep.

        bool match = true;
        if (appliedMaxDeliveryMinutes != null) {
          match = match && minutes <= appliedMaxDeliveryMinutes!;
        }
        if (appliedMinDeliveryMinutes != null) {
          match = match && minutes >= appliedMinDeliveryMinutes!;
        }
        return match;
      }).toList();
    }

    return result;
  }

  int? _parseDeliveryTime(String time) {
    if (time.isEmpty) return null;

    // Remove non-digit characters and parse
    // Handles "30 mins", "10", "45-60 min" (takes the first number)
    final RegExp regExp = RegExp(r'(\d+)');
    final Match? match = regExp.firstMatch(time);

    if (match != null) {
      int value = int.parse(match.group(1)!);
      if (time.toLowerCase().contains('hour')) {
        value *= 60;
      }
      return value;
    }

    return null;
  }
}
