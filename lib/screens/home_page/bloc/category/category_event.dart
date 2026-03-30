import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class CategoryEvent extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class FetchCategory extends CategoryEvent {
  final BuildContext context;
  final String? categoryIds;
  FetchCategory({required this.context, this.categoryIds});
  @override
  // TODO: implement props
  List<Object?> get props => [context, categoryIds];
}

class FetchMoreCategory extends CategoryEvent {}