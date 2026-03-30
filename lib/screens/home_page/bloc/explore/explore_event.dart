import 'package:equatable/equatable.dart';

abstract class ExploreEvent extends Equatable {
  const ExploreEvent();

  @override
  List<Object?> get props => [];
}

class FetchExplores extends ExploreEvent {
  const FetchExplores();
}
