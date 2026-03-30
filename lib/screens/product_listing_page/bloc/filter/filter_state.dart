class FilterState {
  final Set<int> selectedCategoryIds;
  final Set<int> selectedBrandIds;
  final bool isApplied;

  FilterState({
    Set<int>? selectedCategoryIds,
    Set<int>? selectedBrandIds,
    this.isApplied = false,
  })  : selectedCategoryIds = selectedCategoryIds ?? {},
        selectedBrandIds = selectedBrandIds ?? {};

  FilterState copyWith({
    Set<int>? selectedCategoryIds,
    Set<int>? selectedBrandIds,
    bool? isApplied,
  }) {
    return FilterState(
      selectedCategoryIds: selectedCategoryIds ?? Set.from(this.selectedCategoryIds),
      selectedBrandIds: selectedBrandIds ?? Set.from(this.selectedBrandIds),
      isApplied: isApplied ?? this.isApplied,
    );
  }

  int get selectedCategoriesCount => selectedCategoryIds.length;
  int get selectedBrandsCount => selectedBrandIds.length;
  int get totalSelectedCount => selectedCategoriesCount + selectedBrandsCount;

  bool get hasActiveFilters => selectedCategoryIds.isNotEmpty || selectedBrandIds.isNotEmpty;
}
