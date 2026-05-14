import 'package:equatable/equatable.dart';
import '../../model/target_gift_model.dart';

abstract class TargetGiftState extends Equatable {
  const TargetGiftState();

  @override
  List<Object> get props => [];
}

class TargetGiftInitial extends TargetGiftState {}

class TargetGiftLoading extends TargetGiftState {}

class TargetGiftLoaded extends TargetGiftState {
  final TargetGiftModel targetGiftData;

  const TargetGiftLoaded(this.targetGiftData);

  @override
  List<Object> get props => [targetGiftData];
}

class TargetGiftFailed extends TargetGiftState {
  final String error;

  const TargetGiftFailed(this.error);

  @override
  List<Object> get props => [error];
}
