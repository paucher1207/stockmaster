import 'package:isar/isar.dart';

part 'stock_movement_model.g.dart';

@Collection()
class StockMovementModel {
  Id id = Isar.autoIncrement;
  
  late DateTime date;
  late String type;
  late int quantity;
  late String reason;
  late String reference;
  late int productId;
  late int userId;
  late String userName;
  late int previousStock;
  late int newStock;

  // Campos para sincronización
  String? firebaseId;
  bool isSynced = false;
  DateTime? lastSync;

  StockMovementModel() {
    date = DateTime.now();
  }

  StockMovementModel.create({
    required this.type,
    required this.quantity,
    required this.reason,
    required this.reference,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.previousStock,
    required this.newStock,
  }) {
    date = DateTime.now();
  }

  String get typeDisplayName {
    switch (type) {
      case 'entry':
        return 'Entrada';
      case 'exit':
        return 'Salida';
      case 'adjustment':
        return 'Ajuste';
      default:
        return type;
    }
  }

  String get displayQuantity {
    switch (type) {
      case 'entry':
        return '+$quantity';
      case 'exit':
        return '-$quantity';
      case 'adjustment':
        return quantity >= 0 ? '+$quantity' : '$quantity';
      default:
        return quantity.toString();
    }
  }
}