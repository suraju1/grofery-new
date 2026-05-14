import 'package:equatable/equatable.dart';

abstract class TargetGiftEvent extends Equatable {
  const TargetGiftEvent();

  @override
  List<Object> get props => [];
}

class FetchTargetGift extends TargetGiftEvent {}
