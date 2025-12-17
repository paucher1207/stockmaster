import 'package:isar/isar.dart';
import 'package:stockmaster/data/isar/isar_service.dart';
import 'package:stockmaster/data/models/stock_movement_model.dart';

class StockMovementRepository {
  final IsarService _isarService;

  StockMovementRepository(this._isarService);

  Future<void> insertMovement(StockMovementModel movement) async {
    final isar = _isarService.isar;
    await isar.writeTxn(() async {
      await isar.stockMovementModels.put(movement);
    });
  }

  Future<List<StockMovementModel>> getMovementsByProduct(int productId) async {
    final isar = _isarService.isar;
    final movements = await isar.stockMovementModels
        .where()
        .filter()
        .productIdEqualTo(productId)
        .findAll();
    
    movements.sort((a, b) => b.date.compareTo(a.date));
    return movements;
  }

  Future<List<StockMovementModel>> getAllMovements({int limit = 100}) async {
    final isar = _isarService.isar;
    final movements = await isar.stockMovementModels.where().findAll();
    
    movements.sort((a, b) => b.date.compareTo(a.date));
    return movements.take(limit).toList();
  }

  Future<List<StockMovementModel>> getRecentMovements(int limit) async {
    return await getAllMovements(limit: limit);
  }

  Future<List<StockMovementModel>> getMovementsByTypeAndDate({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final allMovements = await getAllMovements(limit: 1000);
    
    return allMovements.where((movement) {
      if (type != null && movement.type != type) return false;
      if (startDate != null && movement.date.isBefore(startDate)) return false;
      if (endDate != null && movement.date.isAfter(endDate)) return false;
      return true;
    }).toList();
  }
}