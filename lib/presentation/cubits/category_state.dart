part of 'category_cubit.dart';

abstract class CategoryState {
  const CategoryState();
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<CategoryModel> categories;

  const CategoryLoaded({required this.categories});
}

class CategoryError extends CategoryState {
  final String message;

  const CategoryError({required this.message});
}