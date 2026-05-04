enum ProductListingType {
  category,
  brand,
  store,
  search,
  featuredSection,
  recommended
}

extension ProductListingTypeX on ProductListingType {
  String get name {
    switch (this) {
      case ProductListingType.category:
        return 'category';
      case ProductListingType.brand:
        return 'brand';
      case ProductListingType.store:
        return 'store';
      case ProductListingType.search:
        return 'search';
      case ProductListingType.featuredSection:
        return 'feature-section';
      case ProductListingType.recommended:
        return 'recommended';
    }
  }
}

