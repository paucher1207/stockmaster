// data/repositories/auth_repository.dart
// ignore_for_file: avoid_print

import 'dart:io' show Platform; // <-- IMPORTANTE: Añadido para plataforma
import 'package:isar/isar.dart';
import 'package:stockmaster/data/isar/isar_service.dart';
import 'package:stockmaster/data/firebase/firebase_auth_service.dart';
import 'package:stockmaster/data/firebase/firestore_service.dart';
import 'package:stockmaster/data/firebase/sync_service.dart';
import 'package:stockmaster/data/models/user_model.dart';

class AuthRepository {
  final IsarService _isarService;
  final FirebaseAuthService _firebaseAuthService;
  final SyncService _syncService;
  final FirestoreService _firestoreService;
  
  AuthRepository({
    required IsarService isarService,
    required FirebaseAuthService firebaseAuthService,
    required SyncService syncService,
    required FirestoreService firestoreService,
  }) : _isarService = isarService,
       _firebaseAuthService = firebaseAuthService,
       _syncService = syncService,
       _firestoreService = firestoreService;
  
  // Login híbrido (local + Firebase)
  Future<UserModel?> login(String username, String password) async {
    try {
      print('🔐 Iniciando login para usuario: $username');
      
      // 1. Buscar usuario en base de datos local
      final localUser = await _isarService.getUserByUsername(username);
      
      if (localUser == null) {
        print('❌ Usuario no encontrado localmente: $username');
        throw Exception('Usuario o contraseña incorrectos');
      }
      
      // 2. Verificar contraseña local
      if (localUser.password != password) {
        print('❌ Contraseña incorrecta para usuario: $username');
        throw Exception('Usuario o contraseña incorrectos');
      }
      
      print('✅ Usuario local validado: ${localUser.fullName}');
      print('📧 Email del usuario: ${localUser.email}');
      print('🔑 FirebaseId actual: ${localUser.firebaseId ?? "No asignado"}');
      
      // 3. MODIFICACIÓN CRÍTICA: Autenticar en Firebase (excepto en Windows)
      if (localUser.email.isNotEmpty && !Platform.isWindows) { // <-- ¡CAMBIO AQUÍ!
        print('🌐 Intentando autenticar en Firebase con email: ${localUser.email}');
        
        try {
          final firebaseUser = await _firebaseAuthService.loginWithEmailAndPassword(
            localUser.email,
            password,
          );
          
          if (firebaseUser != null) {
            print('✅ Autenticado en Firebase: ${firebaseUser.uid}');
            
            // Actualizar ID de Firebase en el usuario local
            localUser.firebaseId = firebaseUser.uid;
            localUser.isSynced = true;
            localUser.lastSync = DateTime.now();
            
            await _isarService.isar.writeTxn(() async {
              await _isarService.isar.userModels.put(localUser);
            });
            
            // Sincronizar usuario con Firestore
            await _syncUserToFirestore(localUser);
            
            // Intentar sincronizar datos generales
            await _syncService.syncUserData(localUser);
          } else {
            print('⚠️ No se pudo autenticar en Firebase (null returned)');
            print('   Posible causa: Contraseña en Firebase diferente');
          }
        } catch (firebaseError) {
          print('🔥 Error de Firebase: $firebaseError');
          print('⚠️ Continuando en modo local');
        }
      } else if (Platform.isWindows) {
        // Mensaje específico para Windows
        print('🖥️ Modo Windows: Login local exitoso (Firebase omitido por estabilidad)');
        print('   Nota: La app se mantendrá estable sin sincronización automática');
      } else {
        print('⚠️ Usuario sin email, modo solo local');
      }
      
      return localUser;
      
    } catch (e) {
      print('❌ Error en login: $e');
      rethrow;
    }
  }
  
  // Sincronizar usuario con Firestore
  Future<void> _syncUserToFirestore(UserModel user) async {
    try {
      if (user.firebaseId == null || user.firebaseId!.isEmpty) {
        print('⚠ Usuario ${user.username} sin firebaseId, omitiendo Firestore');
        return;
      }
      
      final userData = {
        'id': user.id,
        'firebaseId': user.firebaseId,
        'username': user.username,
        'email': user.email,
        'fullName': user.fullName,
        'role': _roleToString(user.role),
        'assignedCategoryId': user.assignedCategoryId,
        'isActive': user.isActive,
        'createdAt': user.createdAt.toIso8601String(),
        'lastSync': user.lastSync?.toIso8601String(),
        'isSynced': user.isSynced,
      };
      
      await _firestoreService.createOrUpdateUser(userData);
      
      print('✅ Usuario ${user.username} sincronizado con Firestore');
    } catch (e) {
      print('❌ Error sincronizando usuario con Firestore: $e');
    }
  }
  
  // Actualizar usuarios existentes con emails
  Future<void> updateExistingUsersWithEmails() async {
    try {
      print('🔄 Actualizando usuarios existentes con emails...');
      
      final users = await _isarService.isar.userModels.where().findAll();
      
      // Mapeo de usuarios a sus emails
      final userEmailMap = {
        'admin': 'admin@stockmaster.com',
        'manager_electronica': 'manager.electronica@stockmaster.com',
        'trabajador_electronica': 'worker.electronica@stockmaster.com',
        'manager_muebles': 'manager.muebles@stockmaster.com',
        'trabajador_muebles': 'worker.muebles@stockmaster.com',
      };
      
      bool updated = false;
      for (final user in users) {
        if (userEmailMap.containsKey(user.username) && 
            (user.email.isEmpty || user.email != userEmailMap[user.username])) {
          
          print('📧 Actualizando email para ${user.username}');
          
          await _isarService.isar.writeTxn(() async {
            user.email = userEmailMap[user.username]!;
            await _isarService.isar.userModels.put(user);
          });
          
          updated = true;
        }
      }
      
      if (updated) {
        print('✅ Usuarios actualizados con emails');
      } else {
        print('✅ Usuarios ya tienen emails correctos');
      }
    } catch (e) {
      print('⚠ Error actualizando usuarios: $e');
    }
  }
  
  // Inicializar usuarios en Firestore
  Future<void> initializeFirestoreUsers() async {
    try {
      print('🔥 Inicializando usuarios en Firestore...');
      
      await updateExistingUsersWithEmails();
      
      final users = await _isarService.isar.userModels.where().findAll();
      
      if (users.isEmpty) {
        print('⚠ No hay usuarios locales para sincronizar');
        return;
      }
      
      for (final user in users) {
        if (user.email.isNotEmpty) {
          final userData = {
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
          };
          
          await _firestoreService.createOrUpdateUser(userData);
        }
      }
      
      print('✅ Usuarios inicializados en Firestore');
    } catch (e) {
      print('❌ Error inicializando Firestore: $e');
    }
  }
  
  // Inicializar usuarios de ejemplo CON EMAIL
  Future<void> initializeSampleUsers() async {
    try {
      print('👥 Inicializando usuarios de ejemplo...');
      
      await updateExistingUsersWithEmails();
      
      final existingUsers = await _isarService.isar.userModels.where().findAll();
      if (existingUsers.isNotEmpty) {
        print('✅ Usuarios de ejemplo ya existen, se omiten');
        return;
      }
      
      // Usuarios de ejemplo CON EMAIL para Firebase
      final users = [
        UserModel()
          ..username = 'admin'
          ..password = 'admin123'
          ..fullName = 'Administrador Principal'
          ..email = 'admin@stockmaster.com'
          ..role = UserRole.admin
          ..assignedCategoryId = null
          ..isActive = true
          ..createdAt = DateTime.now(),
        
        UserModel()
          ..username = 'manager_electronica'
          ..password = 'manager123'
          ..fullName = 'Encargado de Electrónica'
          ..email = 'manager.electronica@stockmaster.com'
          ..role = UserRole.manager
          ..assignedCategoryId = 1
          ..isActive = true
          ..createdAt = DateTime.now(),
        
        UserModel()
          ..username = 'trabajador_electronica'
          ..password = 'worker123'
          ..fullName = 'Trabajador de Electrónica'
          ..email = 'worker.electronica@stockmaster.com'
          ..role = UserRole.worker
          ..assignedCategoryId = 1
          ..isActive = true
          ..createdAt = DateTime.now(),
        
        UserModel()
          ..username = 'manager_muebles'
          ..password = 'manager123'
          ..fullName = 'Encargado de Muebles'
          ..email = 'manager.muebles@stockmaster.com'
          ..role = UserRole.manager
          ..assignedCategoryId = 2
          ..isActive = true
          ..createdAt = DateTime.now(),
        
        UserModel()
          ..username = 'trabajador_muebles'
          ..password = 'worker123'
          ..fullName = 'Trabajador de Muebles'
          ..email = 'worker.muebles@stockmaster.com'
          ..role = UserRole.worker
          ..assignedCategoryId = 2
          ..isActive = true
          ..createdAt = DateTime.now(),
      ];
      
      await _isarService.isar.writeTxn(() async {
        for (final user in users) {
          await _isarService.isar.userModels.put(user);
          print('✅ Usuario creado: ${user.username} (${user.email})');
        }
      });
      
      print('✅ Todos los usuarios de ejemplo creados');
      
      // Inicializar en Firestore también
      await initializeFirestoreUsers();
      
    } catch (e) {
      print('⚠ Error creando usuarios de ejemplo: $e');
    }
  }
  
  // Cerrar sesión
  Future<void> logout() async {
    await _firebaseAuthService.signOut();
    print('✅ Sesión cerrada en Firebase');
  }
  
  // Helper para convertir UserRole a string
  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin: return 'admin';
      case UserRole.manager: return 'manager';
      case UserRole.worker: return 'worker';
    }
  }
}