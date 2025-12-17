
part of 'supplier_cubit.dart';

abstract class SupplierState {
  const SupplierState();
}

class SupplierInitial extends SupplierState {}

class SupplierLoading extends SupplierState {}

class SupplierLoaded extends SupplierState {
  final List<SupplierModel> suppliers;

  const SupplierLoaded({required this.suppliers});
}

class SupplierError extends SupplierState {
  final String message;

  const SupplierError({required this.message});
}