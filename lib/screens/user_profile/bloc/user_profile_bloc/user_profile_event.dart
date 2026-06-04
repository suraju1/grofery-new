part of 'user_profile_bloc.dart';

abstract class UserProfileEvent extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class FetchUserProfile extends UserProfileEvent {}

class UpdateUserProfile extends UserProfileEvent {
  final String userName;
  final File? userImage;
  final String? gstNumber;

  UpdateUserProfile({required this.userName, this.userImage, this.gstNumber});

  @override
  List<Object?> get props => [userName, userImage, gstNumber];
}

class DeleteUser extends UserProfileEvent {}

class ResetUserProfile extends UserProfileEvent {}
