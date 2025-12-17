// data/firebase/firebase_initializer.dart
// ignore_for_file: avoid_print

import 'package:isar/isar.dart';
import 'package:stockmaster/data/firebase/firestore_service.dart';
import 'package:stockmaster/data/isar/isar_service.dart';
import 'package:stockmaster/data/models/user_model.dart';

class FirebaseInitializer {
  final FirestoreService _firestoreService;
  final IsarService _isarService;
  
  FirebaseInitializer(this._firestoreService, this._isarService);
  
  // Inicializar usuarios en Firestore
  Future<void> initializeFirestoreUsers() async {
    try {
      print('🔥 Inicializando usuarios en Firestore...');
      
      // Obtener todos los usuarios locales
      final users = await _isarService.isar.userModels.where().findAll();
      
      if (users.isEmpty) {
        print('⚠ No hay usuarios locales para sincronizar');
        return;
      }
      
      for (final user in users) {
        // Crear documento en Firestore
        await _firestoreService.createOrUpdateUser({
          'id': user.id,
          'username': user.username,
          'email': user.email,
          'fullName': user.fullName,
          'role': _roleToString(user.role),
          'assignedCategoryId': user.assignedCategoryId,
          'isActive': user.isActive,
          'createdAt': user.createdAt.toIso8601String(),
          'isSynced': user.isSynced,
          'lastSync': user.lastSync?.toIso8601String(),
          'firebaseId': user.firebaseId,
        });
      }
      
      print('✅ Usuarios inicializados en Firestore');
    } catch (e) {
      print('❌ Error inicializando Firestore: $e');
    }
  }
  
  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin: return 'admin';
      case UserRole.manager: return 'manager';
      case UserRole.worker: return 'worker';
    }
  }
}