import 'package:equatable/equatable.dart';

import '../../model/user_wishlist_model.dart';

abstract class UserWishlistState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserWishlistInitial extends UserWishlistState {}

class UserWishlistLoading extends UserWishlistState {}

class UserWishlistLoaded extends UserWishlistState {
  final String message;
  final List<WishlistData> wishlistData;
  final bool hasReachedMax;
  final DateTime? timestamp;

  UserWishlistLoaded({
    required this.message,
    required this.wishlistData,
    required this.hasReachedMax,
    this.timestamp,
  });

  UserWishlistLoaded copyWith({
    String? message,
    List<WishlistData>? wishlistData,
    bool? hasReachedMax,
    DateTime? timestamp,
  }) {
    return UserWishlistLoaded(
      message: message ?? this.message,
      wishlistData: wishlistData ?? this.wishlistData,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [message, wishlistData, hasReachedMax, timestamp];
}

class UserWishlistFailed extends UserWishlistState {
  final String message;

  UserWishlistFailed({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}
