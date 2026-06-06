abstract class ManageOutletsEvent {}

class FetchOutlets extends ManageOutletsEvent {}

class AddOutlet extends ManageOutletsEvent {
  final Map<String, dynamic> outletData;
  AddOutlet({required this.outletData});
}

class DeleteOutlet extends ManageOutletsEvent {
  final int id;
  DeleteOutlet({required this.id});
}
