import 'package:equatable/equatable.dart';

abstract class FilterEvent extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class InitializeFilters extends FilterEvent {}

class ToggleCategorySelection extends FilterEvent {
  final int categoryId;

  ToggleCategorySelection(this.categoryId);
}

class ToggleBrandSelection extends FilterEvent {
  final int brandId;

  ToggleBrandSelection(this.brandId);
}

class ClearAllFilters extends FilterEvent {}

class ApplyFilters extends FilterEvent {}
