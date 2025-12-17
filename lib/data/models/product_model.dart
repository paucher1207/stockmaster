import 'package:isar/isar.dart';

part 'product_model.g.dart';

@Collection()
class ProductModel {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String code;
  @Index()
  late String name;

  String? description;
  late double price;
  late double cost;
  late int stock;
  late int minStock;
  String? imagePath;
  @Index()
  late DateTime createdAt;
  @Index()
  late DateTime updatedAt;

  @Index()
  int? categoryId;
  @Index()
  int? supplierId;

  // Campos para sincronización
  String? firebaseId;
  bool isSynced = false;
  DateTime? lastSync;
  String? userId;

  ProductModel() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    code = 'PROD${DateTime.now().millisecondsSinceEpoch}';
  }

  void updateTimestamp() {
    updatedAt = DateTime.now();
    isSynced = false; // Marcar como no sincronizado
  }
}