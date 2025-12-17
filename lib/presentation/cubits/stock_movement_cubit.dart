import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockmaster/data/models/stock_movement_model.dart';
import 'package:stockmaster/data/models/user_model.dart';
import 'package:stockmaster/data/repositories/stock_movement_repository.dart';
import 'package:stockmaster/data/repositories/product_repository.dart';

part 'stock_movement_state.dart';

class StockMovementCubit extends Cubit<StockMovementState> {
  final StockMovementRepository _movementRepository;
  final ProductRepository _productRepository;

  StockMovementCubit({
    required StockMovementRepository movementRepository,
    required ProductRepository productRepository,
  })  : _movementRepository = movementRepository,
        _productRepository = productRepository,
        super(StockMovementInitial());

  // Cargar movimientos por producto
  Future<void> loadMovementsByProduct(int productId) async {
    emit(StockMovementLoading());
    try {
      final movements = await _movementRepository.getMovementsByProduct(productId);
      emit(StockMovementLoaded(movements: movements));
    } catch (e) {
      emit(StockMovementError('Error al cargar movimientos: $e'));
    }
  }

  // Cargar todos los movimientos
  Future<void> loadAllMovements() async {
    emit(StockMovementLoading());
    try {
      final movements = await _movementRepository.getAllMovements();
      emit(StockMovementLoaded(movements: movements));
    } catch (e) {
      emit(StockMovementError('Error al cargar movimientos: $e'));
    }
  }

  // Realizar un movimiento de stock
  Future<void> performStockMovement({
    required int productId,
    required String type,
    required int quantity,
    required String reason,
    required String reference,
    required UserModel user,
  }) async {
    emit(StockMovementLoading());
    try {
      await _productRepository.updateStockWithMovement(
        productId: productId,
        movementType: type,
        quantity: quantity,
        reason: reason,
        reference: reference,
        userId: user.id,
        userName: user.fullName,
      );

      // Recargar movimientos después de realizar uno nuevo
      await loadMovementsByProduct(productId);
      
      emit(const StockMovementSuccess('Movimiento realizado exitosamente'));
    } catch (e) {
      emit(StockMovementError('Error al realizar movimiento: $e'));
    }
  }

  // Filtrar movimientos por tipo
  Future<void> filterMovementsByType(String? type) async {
    final currentState = state;
    if (currentState is StockMovementLoaded) {
      try {
        List<StockMovementModel> filteredMovements;
        
        if (type == null) {
          // Sin filtro, mostrar todos
          await loadAllMovements();
        } else {
          filteredMovements = await _movementRepository.getMovementsByTypeAndDate(type: type);
          emit(StockMovementLoaded(movements: filteredMovements));
        }
      } catch (e) {
        emit(StockMovementError('Error al filtrar movimientos: $e'));
      }
    }
  }
}