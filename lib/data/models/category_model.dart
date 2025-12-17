import 'package:isar/isar.dart';

part 'category_model.g.dart';

@Collection()
class CategoryModel {
  Id id = Isar.autoIncrement;
  
  late String name;
  late String description;
  late DateTime createdAt;

  // Campos para sincronización
  String? firebaseId;
  bool isSynced = false;
  DateTime? lastSync;
  String? userId; // Para multi-usuario

  CategoryModel();
}