import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grofery_user/screens/home_page/bloc/recommended_products/recommended_products_event.dart';
import 'package:grofery_user/screens/home_page/bloc/recommended_products/recommended_products_state.dart';
import 'package:grofery_user/screens/home_page/repo/recommended_products_repo.dart';
import 'package:grofery_user/screens/home_page/model/featured_section_product_model.dart';
import 'package:grofery_user/screens/product_detail_page/model/product_detail_model.dart';

class RecommendedProductsBloc extends Bloc<RecommendedProductsEvent, RecommendedProductsState> {
  final RecommendedProductsRepository repository;

  RecommendedProductsBloc(this.repository) : super(RecommendedProductsInitial()) {
    on<FetchRecommendedProducts>(_onFetchRecommendedProducts);
    on<ClearRecommendedProducts>(_onClearRecommendedProducts);
  }

  void _onClearRecommendedProducts(ClearRecommendedProducts event, Emitter<RecommendedProductsState> emit) {
    emit(RecommendedProductsInitial());
  }

  Future<void> _onFetchRecommendedProducts(FetchRecommendedProducts event, Emitter<RecommendedProductsState> emit) async {
    emit(RecommendedProductsLoading());
    try {
      final response = await repository.fetchRecommendedProducts();

      if (response['success'] == true && response['data'] != null) {
        List<ProductData> products = [];
        // Support direct list parsing in case the API provides just a List of data
        if (response['data'] is List) {
           for (var p in response['data']) {
             try {
               products.add(ProductData.fromJson(p));
             } catch (e) {
               log('⚠️ RECOMMENDED_BLOC: Error parsing individual product: $e');
             }
           }
        } 
        
        // Wrap the products into a FeatureSectionData block!
        final recommendedSectionData = FeatureSectionData(
          id: -1, // Use phantom id to ensure it doesn't collide with existing feature sections
          title: 'Recommended',
          slug: 'recommended',
          style: 'style_1', // Provide a default style to prevent null check error in UI
          products: products,
        );

        log('🟢 RECOMMENDED_BLOC: Fetched ${products.length} products successfully!');

        emit(RecommendedProductsLoaded(
          recommendedData: recommendedSectionData,
          message: response['message'],
        ));
      } else {
        log('🔴 RECOMMENDED_BLOC: API success false! Message: ${response['message']}');
        emit(RecommendedProductsFailed(error: response['message'] ?? 'Failed to load recommendations'));
      }
    } catch (e, st) {
      log('🔴 RECOMMENDED_BLOC: Exception $e\n$st');
      emit(RecommendedProductsFailed(error: e.toString()));
    }
  }
}
