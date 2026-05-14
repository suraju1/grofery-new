import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repo/target_gift_repo.dart';
import '../../model/target_gift_model.dart';
import 'target_gift_event.dart';
import 'target_gift_state.dart';

class TargetGiftBloc extends Bloc<TargetGiftEvent, TargetGiftState> {
  final TargetGiftRepository repository;

  TargetGiftBloc(this.repository) : super(TargetGiftInitial()) {
    on<FetchTargetGift>(_onFetchTargetGift);
  }

  Future<void> _onFetchTargetGift(
    FetchTargetGift event,
    Emitter<TargetGiftState> emit,
  ) async {
    emit(TargetGiftLoading());
    try {
      final data = await repository.fetchTargetGift();
      final targetGiftModel = TargetGiftModel.fromJson(data);
      emit(TargetGiftLoaded(targetGiftModel));
    } catch (e) {
      emit(TargetGiftFailed(e.toString()));
    }
  }
}
