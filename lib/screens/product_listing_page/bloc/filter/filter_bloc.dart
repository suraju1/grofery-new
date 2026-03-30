import 'package:flutter_bloc/flutter_bloc.dart';

import 'filter_event.dart';
import 'filter_state.dart';


class FilterBloc extends Bloc<FilterEvent, FilterState> {
  FilterBloc() : super(FilterState()) {
    on<InitializeFilters>(_onInitializeFilters);
    on<ToggleCategorySelection>(_onToggleCategorySelection);
    on<ToggleBrandSelection>(_onToggleBrandSelection);
    on<ClearAllFilters>(_onClearAllFilters);
    on<ApplyFilters>(_onApplyFilters);
  }

  void _onInitializeFilters(
      InitializeFilters event,
      Emitter<FilterState> emit,
      ) {
    // Initialize with current state (keeps existing selections)
    emit(state);
  }

  void _onToggleCategorySelection(
      ToggleCategorySelection event,
      Emitter<FilterState> emit,
      ) {
    final newSelectedCategories = Set<int>.from(state.selectedCategoryIds);

    if (newSelectedCategories.contains(event.categoryId)) {
      newSelectedCategories.remove(event.categoryId);
    } else {
      newSelectedCategories.add(event.categoryId);
    }

    emit(state.copyWith(
      selectedCategoryIds: newSelectedCategories,
      isApplied: false,
    ));
  }

  void _onToggleBrandSelection(
      ToggleBrandSelection event,
      Emitter<FilterState> emit,
      ) {
    final newSelectedBrands = Set<int>.from(state.selectedBrandIds);

    if (newSelectedBrands.contains(event.brandId)) {
      newSelectedBrands.remove(event.brandId);
    } else {
      newSelectedBrands.add(event.brandId);
    }

    emit(state.copyWith(
      selectedBrandIds: newSelectedBrands,
      isApplied: false,
    ));
  }

  void _onClearAllFilters(
      ClearAllFilters event,
      Emitter<FilterState> emit,
      ) {
    emit(FilterState());
  }

  void _onApplyFilters(
      ApplyFilters event,
      Emitter<FilterState> emit,
      ) {
    emit(state.copyWith(isApplied: true));
  }
}