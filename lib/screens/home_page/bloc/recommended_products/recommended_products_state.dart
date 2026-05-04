import 'package:grofery_user/screens/home_page/model/featured_section_product_model.dart';

abstract class RecommendedProductsState {}

class RecommendedProductsInitial extends RecommendedProductsState {}

class RecommendedProductsLoading extends RecommendedProductsState {}

class RecommendedProductsLoaded extends RecommendedProductsState {
  final FeatureSectionData recommendedData;
  final String? message;

  RecommendedProductsLoaded({
    required this.recommendedData,
    this.message,
  });
}

class RecommendedProductsFailed extends RecommendedProductsState {
  final String error;

  RecommendedProductsFailed({required this.error});
}
