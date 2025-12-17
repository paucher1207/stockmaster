import 'package:isar/isar.dart';

part 'supplier_model.g.dart';

@Collection()
class SupplierModel {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String code;
  late String name;
  late String contact;
  late String phone;
  late String email;
  String? address;
  String? notes;
  late DateTime createdAt;
  late bool isActive;

  // Campos para sincronización
  String? firebaseId;
  bool isSynced = false;
  DateTime? lastSync;
  String? userId;

  SupplierModel() {
    createdAt = DateTime.now();
    isActive = true;
    code = 'PROV${DateTime.now().millisecondsSinceEpoch}';
  }
}