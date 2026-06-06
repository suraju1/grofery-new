import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grofery_user/config/constant.dart';
import '../model/outlet_model.dart';
import 'manage_outlets_event.dart';
import 'manage_outlets_state.dart';

class ManageOutletsBloc extends Bloc<ManageOutletsEvent, ManageOutletsState> {
  ManageOutletsBloc() : super(OutletsInitial()) {
    on<FetchOutlets>((event, emit) async {
      emit(OutletsLoading());
      try {
        final response = await AppConstant.apiBaseHelper.getAPICall(
            '${AppConstant.baseUrl}user/outlets', {},
            isUserApi: true);
        final List<dynamic> data = response.data['data'] ?? [];
        final outlets = data.map((e) => OutletModel.fromJson(e)).toList();
        emit(OutletsLoaded(outlets: outlets));
      } catch (e) {
        emit(OutletsError(message: e.toString()));
      }
    });

    on<AddOutlet>((event, emit) async {
      try {
        await AppConstant.apiBaseHelper.postAPICall(
            '${AppConstant.baseUrl}user/outlets', event.outletData);
        emit(AddOutletSuccess());
      } catch (e) {
        emit(AddOutletError(message: e.toString()));
      }
    });

    on<DeleteOutlet>((event, emit) async {
      try {
        await AppConstant.apiBaseHelper.deleteAPICall(
            '${AppConstant.baseUrl}user/outlets/${event.id}', {});
        add(FetchOutlets());
      } catch (e) {
        emit(OutletsError(message: e.toString()));
      }
    });
  }
}
