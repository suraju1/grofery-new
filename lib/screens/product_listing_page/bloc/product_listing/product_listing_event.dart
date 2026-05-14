part of 'product_listing_bloc.dart';

abstract class ProductListingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchFilteredAndSortedProduct extends ProductListingEvent {
  final String categorySlug;
  final String sortType;
  FetchFilteredAndSortedProduct(
      {required this.categorySlug, required this.sortType});
  @override
  List<Object?> get props => [categorySlug, sortType];
}

class FetchListingProducts extends ProductListingEvent {
  final ProductListingType type;
  final String identifier;
  final String? storeSlug;
  final String? sortType;
  final bool? isSearchInStore;
  final String? includeChildCategories;
  final String? indicator;
  final double? rating;
  final List<String>? brandSlugs;
  final List<String>? categorySlugs;

  FetchListingProducts({
    required this.type,
    required this.identifier,
    this.storeSlug,
    this.sortType,
    this.isSearchInStore,
    this.includeChildCategories,
    this.indicator,
    this.rating,
    this.brandSlugs,
    this.categorySlugs,
  });

  @override
  List<Object?> get props => [
        type,
        identifier,
        storeSlug,
        sortType,
        isSearchInStore,
        includeChildCategories,
        indicator,
        rating,
        brandSlugs,
        categorySlugs,
      ];
}

class FetchSortedListingProducts extends ProductListingEvent {
  final ProductListingType type;
  final String identifier;
  final String? storeSlug;
  final String sortType;
  final bool? isSearchInStore;
  final String? indicator;
  final double? rating;

  FetchSortedListingProducts({
    required this.type,
    required this.identifier,
    this.storeSlug,
    required this.sortType,
    this.isSearchInStore,
    this.indicator,
    this.rating,
  });

  @override
  List<Object?> get props => [
        type,
        identifier,
        storeSlug,
        sortType,
        isSearchInStore,
        indicator,
        rating
      ];
}

class FetchMoreListingProducts extends ProductListingEvent {
  final ProductListingType type;
  final String identifier;
  final String? storeSlug;
  final String? sortType;
  final bool? isSearchInStore;
  final String? indicator;
  final double? rating;

  FetchMoreListingProducts({
    required this.type,
    required this.identifier,
    this.storeSlug,
    this.sortType,
    this.isSearchInStore,
    this.indicator,
    this.rating,
  });

  @override
  List<Object?> get props => [
        type,
        identifier,
        storeSlug,
        sortType,
        isSearchInStore,
        indicator,
        rating
      ];
}

class FetchKeywords extends ProductListingEvent {
  final String query;
  FetchKeywords({required this.query});
  @override
  List<Object?> get props => [query];
}

class ResetSearchKeywords extends ProductListingEvent {}

class FetchFilteredListingProducts extends ProductListingEvent {
  final ProductListingType type;
  final String identifier;
  final String? storeSlug;
  final bool? isSearchInStore;
  final List<String> categorySlugs;
  final List<String> brandSlugs;
  final String? indicator;
  final double? rating;

  FetchFilteredListingProducts({
    required this.type,
    required this.identifier,
    this.storeSlug,
    this.isSearchInStore,
    required this.categorySlugs,
    required this.brandSlugs,
    this.indicator,
    this.rating,
  });

  @override
  List<Object?> get props => [
        type,
        identifier,
        storeSlug,
        isSearchInStore,
        categorySlugs,
        brandSlugs,
        indicator,
        rating,
      ];
}

class ApplyFiltersAndSort extends ProductListingEvent {
  final ProductListingType type;
  final String identifier;
  final String? storeSlug;
  final String sortType;
  final bool? isSearchInStore;
  final List<String> categorySlugs;
  final List<String> brandSlugs;
  final String? indicator;
  final double? rating;

  ApplyFiltersAndSort({
    required this.type,
    required this.identifier,
    this.storeSlug,
    required this.sortType,
    this.isSearchInStore,
    required this.categorySlugs,
    required this.brandSlugs,
    this.indicator,
    this.rating,
  });

  @override
  List<Object?> get props => [
        type,
        identifier,
        storeSlug,
        sortType,
        isSearchInStore,
        categorySlugs,
        brandSlugs,
        indicator,
        rating,
      ];
}

class ClearProductFilters extends ProductListingEvent {
  final ProductListingType type;
  final String identifier;
  final String? storeSlug;
  final bool? isSearchInStore;

  ClearProductFilters({
    required this.type,
    required this.identifier,
    this.storeSlug,
    this.isSearchInStore,
  });

  @override
  List<Object?> get props => [type, identifier, storeSlug, isSearchInStore];
}

class FilterByDeliveryTime extends ProductListingEvent {
  final int? maxMinutes;
  final int? minMinutes;
  final bool? quickDeliveryOnly;

  FilterByDeliveryTime({this.maxMinutes, this.minMinutes, this.quickDeliveryOnly});

  @override
  List<Object?> get props => [maxMinutes, minMinutes, quickDeliveryOnly];
}
