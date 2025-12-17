// presentation/cubits/supplier_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockmaster/data/models/supplier_model.dart';
import 'package:stockmaster/data/repositories/supplier_repository.dart';

part 'supplier_state.dart';

class SupplierCubit extends Cubit<SupplierState> {
  final SupplierRepository _supplierRepository;

  SupplierCubit({required SupplierRepository supplierRepository})
      : _supplierRepository = supplierRepository,
        super(SupplierInitial());

  Future<void> loadSuppliers() async {
    emit(SupplierLoading());
    try {
      final suppliers = await _supplierRepository.getAllSuppliers();
      emit(SupplierLoaded(suppliers: suppliers));
    } catch (e) {
      emit(SupplierError(message: 'Error al cargar proveedores: $e'));
    }
  }

  Future<void> addSupplier(SupplierModel supplier) async {
    try {
      await _supplierRepository.createSupplier(supplier);
      await loadSuppliers();
    } catch (e) {
      emit(SupplierError(message: 'Error al agregar proveedor: $e'));
    }
  }

  Future<void> updateSupplier(SupplierModel supplier) async {
    try {
      await _supplierRepository.updateSupplier(supplier);
      await loadSuppliers();
    } catch (e) {
      emit(SupplierError(message: 'Error al actualizar proveedor: $e'));
    }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      await _supplierRepository.deleteSupplier(id);
      await loadSuppliers();
    } catch (e) {
      emit(SupplierError(message: 'Error al eliminar proveedor: $e'));
    }
  }

  Future<void> searchSuppliers(String query) async {
    if (query.isEmpty) {
      await loadSuppliers();
      return;
    }

    emit(SupplierLoading());
    try {
      final suppliers = await _supplierRepository.searchSuppliers(query);
      emit(SupplierLoaded(suppliers: suppliers));
    } catch (e) {
      emit(SupplierError(message: 'Error al buscar proveedores: $e'));
    }
  }

  void loadSampleData() {}
}