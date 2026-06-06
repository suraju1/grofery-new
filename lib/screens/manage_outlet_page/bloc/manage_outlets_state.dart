import '../model/outlet_model.dart';

abstract class ManageOutletsState {}

class OutletsInitial extends ManageOutletsState {}

class OutletsLoading extends ManageOutletsState {}

class OutletsLoaded extends ManageOutletsState {
  final List<OutletModel> outlets;
  OutletsLoaded({required this.outlets});
}

class OutletsError extends ManageOutletsState {
  final String message;
  OutletsError({required this.message});
}

class AddOutletSuccess extends ManageOutletsState {}

class AddOutletError extends ManageOutletsState {
  final String message;
  AddOutletError({required this.message});
}
