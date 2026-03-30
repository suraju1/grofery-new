import 'package:equatable/equatable.dart';
import '../../model/explore_model.dart';

abstract class ExploreState extends Equatable {
  const ExploreState();

  @override
  List<Object?> get props => [];
}

class ExploreInitial extends ExploreState {}

class ExploreLoading extends ExploreState {}

class ExploreLoaded extends ExploreState {
  final List<ExploreData> exploreData;
  final String? message;
  final int totalCount;

  const ExploreLoaded({
    required this.exploreData,
    this.message,
    this.totalCount = 0,
  });

  @override
  List<Object?> get props => [exploreData, message, totalCount];
}

class ExploreFailed extends ExploreState {
  final String error;

  const ExploreFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
