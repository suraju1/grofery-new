import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'explore_event.dart';
import 'explore_state.dart';
import '../../repo/explore_repo.dart';
import '../../model/explore_model.dart';

class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  final ExploreRepository repository = ExploreRepository();

  ExploreBloc() : super(ExploreInitial()) {
    on<FetchExplores>(_onFetchExplores);
  }

  Future<void> _onFetchExplores(
      FetchExplores event, Emitter<ExploreState> emit) async {
    emit(ExploreLoading());
    try {
      debugPrint("DEBUG_API: [ExploreBloc._onFetchExplores] Event received");
      final response = await repository.fetchExplores();
      if (response['success'] == true && response['data'] != null) {
        final exploreModel = ExploreModel.fromJson(response);

        emit(ExploreLoaded(
          exploreData: exploreModel.data?.data ?? [],
          message: exploreModel.message,
          totalCount: exploreModel.data?.total ?? 0,
        ));
      } else {
        emit(ExploreFailed(
            error: response['message'] ?? 'Failed to fetch explores'));
      }
    } catch (e) {
      emit(ExploreFailed(error: e.toString()));
    }
  }
}
