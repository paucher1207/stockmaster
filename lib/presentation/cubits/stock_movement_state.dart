part of 'stock_movement_cubit.dart';

abstract class StockMovementState {
  const StockMovementState();
}

class StockMovementInitial extends StockMovementState {}

class StockMovementLoading extends StockMovementState {}

class StockMovementLoaded extends StockMovementState {
  final List<StockMovementModel> movements;

  const StockMovementLoaded({required this.movements});
}

class StockMovementSuccess extends StockMovementState {
  final String message;

  const StockMovementSuccess(this.message);
}

class StockMovementError extends StockMovementState {
  final String message;

  const StockMovementError(this.message);
}