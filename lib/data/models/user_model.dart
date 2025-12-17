import 'package:isar/isar.dart';

part 'user_model.g.dart';

@Collection()
class UserModel {
  Id id = Isar.autoIncrement;
  
  String username = '';
  String password = '';
  String fullName = '';
  String email = ''; 
  @enumerated 
  UserRole role = UserRole.worker;
  
  @Index()
  int? assignedCategoryId;
  
  bool isActive = true;
  DateTime createdAt = DateTime.now();
  
  String? firebaseId;
  bool isSynced = false;
  DateTime? lastSync;
  
  // Getters para compatibilidad
  bool get isAdmin => role == UserRole.admin;
  bool get isManager => role == UserRole.manager;
  bool get isWorker => role == UserRole.worker;
  
  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.manager:
        return 'Encargado';
      case UserRole.worker:
        return 'Trabajador';
    }
  }
  
  bool get canViewAllProducts => role == UserRole.admin;
  bool get canEditProducts => role == UserRole.admin || role == UserRole.manager;
  bool get canManageCategories => role == UserRole.admin;
  bool get canManageSuppliers => role == UserRole.admin;
  bool get canViewDashboard => role == UserRole.admin || role == UserRole.manager;
  
  bool hasAccessToCategory(int categoryId) {
    if (role == UserRole.admin) return true;
    return assignedCategoryId == categoryId;
  }
}

enum UserRole {
  admin,
  manager,
  worker,
}