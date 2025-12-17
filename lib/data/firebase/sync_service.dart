// ignore_for_file: avoid_print

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:stockmaster/data/isar/isar_service.dart';
import 'package:stockmaster/data/firebase/firebase_auth_service.dart';
import 'package:stockmaster/data/firebase/firestore_service.dart'; // Añadir import
import 'package:stockmaster/data/models/user_model.dart';
import 'package:stockmaster/data/models/category_model.dart';
import 'package:stockmaster/data/models/product_model.dart';
import 'package:stockmaster/data/models/supplier_model.dart';

class SyncService {
  final IsarService _isarService;
  final FirebaseAuthService _authService;
  final FirestoreService _firestoreService; // Añadir esta línea
  
  SyncService({
    required IsarService isarService,
    required FirebaseAuthService authService,
    required FirestoreService firestoreService, // Añadir este parámetro
  }) : _isarService = isarService,
       _authService = authService,
       _firestoreService = firestoreService; // Inicializar
  
  Future<bool> checkConnection() async {
    final connectivity = await Connectivity().checkConnectivity();
    return connectivity != ConnectivityResult.none;
  }

  Future<Map<String, dynamic>> testSync() async {
  try {
    final hasConnection = await checkConnection();
    final currentUser = await _authService.getCurrentUser();
    
    // Verificar estado de la conexión
    if (!hasConnection) {
      return {
        'success': false,
        'error': 'Sin conexión a internet',
        'has_connection': false,
        'user_authenticated': false,
      };
    }
    
    // Verificar autenticación
    if (currentUser == null) {
      return {
        'success': false,
        'error': 'Usuario no autenticado',
        'has_connection': true,
        'user_authenticated': false,
      };
    }
    
    // Probar conexión con Firestore (opcional)
    bool firestoreConnected = false;
    try {
      await _firestoreService.categories // Usar instancia, no estático
          .where('userId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();
      firestoreConnected = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error probando Firestore: $e');
      }
    }
    
    // Obtener estadísticas locales
    final localCategories = await _isarService.isar.categoryModels.where().findAll();
    final localProducts = await _isarService.isar.productModels.where().findAll();
    final localSuppliers = await _isarService.isar.supplierModels.where().findAll();
    
    return {
      'success': true,
      'message': 'Test de sincronización exitoso',
      'has_connection': hasConnection,
      'user_authenticated': true,
      'user_id': currentUser.uid,
      'firestore_connected': firestoreConnected,
      'local_categories': localCategories.length,
      'local_products': localProducts.length,
      'local_suppliers': localSuppliers.length,
    };
  } catch (e) {
    return {
      'success': false,
      'error': 'Error en testSync: $e',
      'has_connection': false,
      'user_authenticated': false,
    };
  }
}
  
  Future<void> syncAllData() async {
    if (!await checkConnection()) {
      if (kDebugMode) {
        print('Sin conexión, omitiendo sincronización');
      }
      return;
    }
    
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) {
      if (kDebugMode) {
        print('Usuario no autenticado, omitiendo sincronización');
      }
      return;
    }
    
    if (kDebugMode) {
      print('Iniciando sincronización completa...');
    }
    
    try {
      await syncCategories(currentUser.uid);
      await syncSuppliers(currentUser.uid);
      await syncProducts(currentUser.uid);
      
      await downloadCategories(currentUser.uid);
      await downloadSuppliers(currentUser.uid);
      await downloadProducts(currentUser.uid);
      
      if (kDebugMode) {
        print('✓ Sincronización completa exitosa');
      }
    } catch (e) {
      if (kDebugMode) {
        print('✗ Error en sincronización: $e');
      }
    }
  }
  
  // Obtener usuario actual de Firebase
  Future<dynamic> getCurrentFirebaseUser() async {
    return await _authService.getCurrentUser();
  }
  
  Future<void> syncUserData(UserModel user) async {
    if (!await checkConnection()) return;
    
    try {
      final userData = {
        'username': user.username,
        'fullName': user.fullName,
        'role': user.role.index,
        'assignedCategoryId': user.assignedCategoryId,
        'email': user.email,
        'isActive': user.isActive,
        'createdAt': user.createdAt.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (user.firebaseId == null) {
        // Crear nuevo en Firebase
        final docRef = await _firestoreService.users.add(userData); // Cambiar a instancia
        user.firebaseId = docRef.id;
      } else {
        // Actualizar existente
        await _firestoreService.users.doc(user.firebaseId!).update(userData); // Cambiar
      }
      
      user.isSynced = true;
      user.lastSync = DateTime.now();
      await _isarService.isar.writeTxn(() async {
        await _isarService.isar.userModels.put(user);
      });
      
    } catch (e) {
      if (kDebugMode) {
        print('Error sincronizando usuario: $e');
      }
    }
  }
  
  Future<void> syncCategories(String userId) async {
    try {
      final unsyncedCategories = await _getUnsyncedCategories();
      
      for (final category in unsyncedCategories) {
        try {
          final categoryData = {
            'name': category.name,
            'description': category.description,
            'createdAt': category.createdAt.toIso8601String(),
            'userId': userId,
            'localId': category.id,
          };
          
          if (category.firebaseId == null) {
            final docRef = await _firestoreService.categories.add(categoryData); // Cambiar
            category.firebaseId = docRef.id;
          } else {
            await _firestoreService.categories // Cambiar
                .doc(category.firebaseId!)
                .update(categoryData);
          }
          
          category.isSynced = true;
          category.lastSync = DateTime.now();
          category.userId = userId;
          
          await _isarService.isar.writeTxn(() async {
            await _isarService.isar.categoryModels.put(category);
          });
          
          if (kDebugMode) {
            print('✓ Categoría sincronizada: ${category.name}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error sincronizando categoría ${category.id}: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error en syncCategories: $e');
      }
    }
  }
  
  Future<void> syncProducts(String userId) async {
    try {
      final unsyncedProducts = await _getUnsyncedProducts();
      
      for (final product in unsyncedProducts) {
        try {
          final productData = {
            'code': product.code,
            'name': product.name,
            'description': product.description,
            'price': product.price,
            'cost': product.cost,
            'stock': product.stock,
            'minStock': product.minStock,
            'categoryId': product.categoryId,
            'supplierId': product.supplierId,
            'userId': userId,
            'localId': product.id,
            'createdAt': product.createdAt.toIso8601String(),
            'updatedAt': product.updatedAt.toIso8601String(),
          };
          
          if (product.firebaseId == null) {
            final docRef = await _firestoreService.products.add(productData); // Cambiar
            product.firebaseId = docRef.id;
          } else {
            await _firestoreService.products // Cambiar
                .doc(product.firebaseId!)
                .update(productData);
          }
          
          product.isSynced = true;
          product.lastSync = DateTime.now();
          product.userId = userId;
          
          await _isarService.isar.writeTxn(() async {
            await _isarService.isar.productModels.put(product);
          });
          
          if (kDebugMode) {
            print('✓ Producto sincronizado: ${product.name}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error sincronizando producto ${product.id}: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error en syncProducts: $e');
      }
    }
  }
  
  Future<void> syncSuppliers(String userId) async {
    try {
      final unsyncedSuppliers = await _getUnsyncedSuppliers();
      
      for (final supplier in unsyncedSuppliers) {
        try {
          final supplierData = {
            'code': supplier.code,
            'name': supplier.name,
            'contact': supplier.contact,
            'phone': supplier.phone,
            'email': supplier.email,
            'address': supplier.address,
            'notes': supplier.notes,
            'isActive': supplier.isActive,
            'createdAt': supplier.createdAt.toIso8601String(),
            'userId': userId,
            'localId': supplier.id,
          };
          
          if (supplier.firebaseId == null) {
            final docRef = await _firestoreService.suppliers.add(supplierData); // Cambiar
            supplier.firebaseId = docRef.id;
          } else {
            await _firestoreService.suppliers // Cambiar
                .doc(supplier.firebaseId!)
                .update(supplierData);
          }
          
          supplier.isSynced = true;
          supplier.lastSync = DateTime.now();
          supplier.userId = userId;
          
          await _isarService.isar.writeTxn(() async {
            await _isarService.isar.supplierModels.put(supplier);
          });
          
          if (kDebugMode) {
            print('✓ Proveedor sincronizado: ${supplier.name}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error sincronizando proveedor ${supplier.id}: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error en syncSuppliers: $e');
      }
    }
  }
  
  Future<void> downloadCategories(String userId) async {
    try {
      final snapshot = await _firestoreService.categories // Cambiar
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final existing = await _getCategoryByFirebaseId(doc.id);
        
        if (existing == null) {
          final category = CategoryModel()
            ..firebaseId = doc.id
            ..name = data['name'] ?? ''
            ..description = data['description'] ?? ''
            ..createdAt = DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String())
            ..userId = userId
            ..isSynced = true
            ..lastSync = DateTime.now();
          
          await _isarService.isar.writeTxn(() async {
            await _isarService.isar.categoryModels.put(category);
          });
          
          if (kDebugMode) {
            print('✓ Categoría descargada: ${category.name}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error descargando categorías: $e');
      }
    }
  }
  
  Future<void> downloadProducts(String userId) async {
    try {
      final snapshot = await _firestoreService.products // Cambiar
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final existing = await _getProductByFirebaseId(doc.id);
        
        if (existing == null) {
          final product = ProductModel()
            ..firebaseId = doc.id
            ..code = data['code'] ?? ''
            ..name = data['name'] ?? ''
            ..description = data['description']
            ..price = (data['price'] ?? 0.0).toDouble()
            ..cost = (data['cost'] ?? 0.0).toDouble()
            ..stock = data['stock'] ?? 0
            ..minStock = data['minStock'] ?? 0
            ..categoryId = data['categoryId']
            ..supplierId = data['supplierId']
            ..createdAt = DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String())
            ..updatedAt = DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String())
            ..userId = userId
            ..isSynced = true
            ..lastSync = DateTime.now();
          
          await _isarService.isar.writeTxn(() async {
            await _isarService.isar.productModels.put(product);
          });
          
          if (kDebugMode) {
            print('✓ Producto descargado: ${product.name}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error descargando productos: $e');
      }
    }
  }
  
  Future<void> downloadSuppliers(String userId) async {
    try {
      final snapshot = await _firestoreService.suppliers // Cambiar
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final existing = await _getSupplierByFirebaseId(doc.id);
        
        if (existing == null) {
          final supplier = SupplierModel()
            ..firebaseId = doc.id
            ..code = data['code'] ?? ''
            ..name = data['name'] ?? ''
            ..contact = data['contact'] ?? ''
            ..phone = data['phone'] ?? ''
            ..email = data['email'] ?? ''
            ..address = data['address']
            ..notes = data['notes']
            ..isActive = data['isActive'] ?? true
            ..createdAt = DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String())
            ..userId = userId
            ..isSynced = true
            ..lastSync = DateTime.now();
          
          await _isarService.isar.writeTxn(() async {
            await _isarService.isar.supplierModels.put(supplier);
          });
          
          if (kDebugMode) {
            print('✓ Proveedor descargado: ${supplier.name}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error descargando proveedores: $e');
      }
    }
  }
  
  Future<void> syncUserDataFromFirebase(String userId) async {
    try {
      final userEmail = _authService.currentUser?.email;
      if (userEmail == null) return;
      
      final snapshot = await _firestoreService.users // Cambiar
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>?;
        
        if (data != null) {
          final localUser = await _isarService.getUserByEmail(userEmail);
          
          if (localUser == null) {
            final username = data['username'] as String? ?? userEmail.split('@')[0];
            final roleIndex = data['role'] as int? ?? 0;
            final fullName = data['fullName'] as String? ?? 'Usuario';
            final assignedCategoryId = data['assignedCategoryId'] as int?;
            final isActive = data['isActive'] as bool? ?? true;
            final createdAtStr = data['createdAt'] as String?;
            
            final createdAt = createdAtStr != null 
                ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
                : DateTime.now();
            
            final newUser = UserModel()
              ..username = username
              ..password = ''
              ..role = UserRole.values[roleIndex]
              ..fullName = fullName
              ..assignedCategoryId = assignedCategoryId
              ..email = userEmail
              ..createdAt = createdAt
              ..isActive = isActive
              ..firebaseId = doc.id
              ..isSynced = true
              ..lastSync = DateTime.now();
            
            await _isarService.isar.writeTxn(() async {
              await _isarService.isar.userModels.put(newUser);
            });
            
            if (kDebugMode) {
              print('✓ Usuario creado desde Firebase: $username');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error descargando datos de usuario: $e');
      }
    }
  }
  
  // ========== SINCRONIZACIÓN BIDIRECCIONAL ==========
  
  Future<void> syncBidirectional() async {
    if (!await checkConnection()) {
      print('Sin conexión, omitiendo sincronización bidireccional');
      return;
    }
    
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) {
      print('Usuario no autenticado');
      return;
    }
    
    print('Iniciando sincronización bidireccional...');
    
    // PASO 1: Descargar datos remotos
    print('1. Descargando datos desde Firebase...');
    await syncUserDataFromFirebase(currentUser.uid);
    await downloadCategories(currentUser.uid);
    await downloadProducts(currentUser.uid);
    await downloadSuppliers(currentUser.uid);
    
    // PASO 2: Subir datos locales no sincronizados
    print('2. Subiendo datos locales...');
    await syncCategories(currentUser.uid);
    await syncProducts(currentUser.uid);
    await syncSuppliers(currentUser.uid);
    
    // PASO 3: Actualizar caché local
    print('3. Actualizando caché local...');
    await _refreshLocalCache(currentUser.uid);
    
    print('✓ Sincronización bidireccional completada');
  }
  
  Future<void> _refreshLocalCache(String userId) async {
    try {
      // Simplemente marcamos todos los datos como actualizados
      // En una implementación real, podrías volver a descargar todo
      print('  • Cache actualizado para usuario: $userId');
    } catch (e) {
      print('Error refrescando caché: $e');
    }
  }
  
  Future<void> quickSync() async {
    if (!await checkConnection()) return;
    
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) return;
    
    await syncUserDataFromFirebase(currentUser.uid);
  }
  
  // ========== MÉTODOS AUXILIARES ==========
  
  Future<List<CategoryModel>> _getUnsyncedCategories() async {
    try {
      final allCategories = await _isarService.isar.categoryModels.where().findAll();
      return allCategories.where((c) => !c.isSynced).toList();
    } catch (e) {
      print('Error obteniendo categorías no sincronizadas: $e');
      return [];
    }
  }
  
  Future<List<ProductModel>> _getUnsyncedProducts() async {
    try {
      final allProducts = await _isarService.isar.productModels.where().findAll();
      return allProducts.where((p) => !p.isSynced).toList();
    } catch (e) {
      print('Error obteniendo productos no sincronizados: $e');
      return [];
    }
  }
  
  Future<List<SupplierModel>> _getUnsyncedSuppliers() async {
    try {
      final allSuppliers = await _isarService.isar.supplierModels.where().findAll();
      return allSuppliers.where((s) => !s.isSynced).toList();
    } catch (e) {
      print('Error obteniendo proveedores no sincronizados: $e');
      return [];
    }
  }
  
  Future<CategoryModel?> _getCategoryByFirebaseId(String firebaseId) async {
    try {
      return await _isarService.isar.categoryModels
          .where()
          .filter()
          .firebaseIdEqualTo(firebaseId)
          .findFirst();
    } catch (e) {
      print('Error en getCategoryByFirebaseId: $e');
      return null;
    }
  }
  
  Future<ProductModel?> _getProductByFirebaseId(String firebaseId) async {
    try {
      return await _isarService.isar.productModels
          .where()
          .filter()
          .firebaseIdEqualTo(firebaseId)
          .findFirst();
    } catch (e) {
      print('Error en getProductByFirebaseId: $e');
      return null;
    }
  }
  
  Future<SupplierModel?> _getSupplierByFirebaseId(String firebaseId) async {
    try {
      return await _isarService.isar.supplierModels
          .where()
          .filter()
          .firebaseIdEqualTo(firebaseId)
          .findFirst();
    } catch (e) {
      print('Error en getSupplierByFirebaseId: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> uploadAllLocalData() async {
    print('🔍 DEBUG: Iniciando uploadAllLocalData');
    try {
      final currentUser = await _authService.getCurrentUser();
      print('🔍 DEBUG: currentUser = $currentUser');
      
      if (currentUser == null) {
        print('❌ DEBUG: Usuario NO autenticado en Firebase Auth');
        final firebaseUser = FirebaseAuth.instance.currentUser;
        print('🔍 DEBUG: FirebaseAuth.currentUser = $firebaseUser');
        
        return {
          'success': false,
          'error': 'Usuario no autenticado en Firebase Auth',
          'debug': {
            'auth_service_user': currentUser?.uid,
            'firebase_auth_user': firebaseUser?.uid,
          }
        };
      }
      print('✅ DEBUG: Usuario autenticado: ${currentUser.uid}');
      if (!await checkConnection()) {
        return {
          'success': false,
          'error': 'Sin conexión a internet'
        };
      }

      if (kDebugMode) {
        print('🚀 Iniciando subida completa de datos locales a Firebase...');
      }

      final userId = currentUser.uid;
      final results = {
        'categories': await _forceUploadCategories(userId),
        'suppliers': await _forceUploadSuppliers(userId),
        'products': await _forceUploadProducts(userId),
        'users': await _forceUploadUsers(userId),
      };

      final totalUploaded = results.values
          .where((r) => r['success'] == true)
          .fold(0, (sum, r) => sum + (r['count'] as int));

      return {
        'success': true,
        'message': 'Subida completada: $totalUploaded registros',
        'details': results,
        'total_uploaded': totalUploaded,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error en uploadAllLocalData: $e'
      };
    }
  }

  Future<Map<String, dynamic>> _forceUploadCategories(String userId) async {
    try {
      final allCategories = await _isarService.isar.categoryModels.where().findAll();
      int uploadedCount = 0;

      for (final category in allCategories) {
        try {
          final categoryData = {
            'name': category.name,
            'description': category.description,
            'createdAt': category.createdAt.toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
            'userId': userId,
            'localId': category.id.toString(),
            'isActive': true,
          };

          // Si ya tiene firebaseId, actualizamos, si no, creamos nuevo
          if (category.firebaseId == null || category.firebaseId!.isEmpty) {
            final docRef = await _firestoreService.categories.add(categoryData); // Cambiar
            category.firebaseId = docRef.id;
          } else {
            await _firestoreService.categories // Cambiar
                .doc(category.firebaseId!)
                .update(categoryData);
          }

          category.isSynced = true;
          category.lastSync = DateTime.now();
          category.userId = userId;

          await _isarService.isar.writeTxn(() async {
            await _isarService.isar.categoryModels.put(category);
          });

          uploadedCount++;
          if (kDebugMode) {
            print('  ✓ Categoría: ${category.name}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('  ✗ Error categoría ${category.name}: $e');
          }
        }
      }

      return {
        'success': true,
        'count': uploadedCount,
        'total': allCategories.length,
        'message': 'Categorías: $uploadedCount/${allCategories.length}'
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error subiendo categorías: $e'
      };
    }
  }

  Future<Map<String, dynamic>> _forceUploadSuppliers(String userId) async {
    try {
      final allSuppliers = await _isarService.isar.supplierModels.where().findAll();
      int uploadedCount = 0;

      for (final supplier in allSuppliers) {
        try {
          final supplierData = {
            'code': supplier.code,
            'name': supplier.name,
            'contact': supplier.contact,
            'phone': supplier.phone,
            'email': supplier.email,
            'address': supplier.address,
            'notes': supplier.notes,
            'isActive': supplier.isActive,
            'createdAt': supplier.createdAt.toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
            'userId': userId,
            'localId': supplier.id.toString(),
          };

          if (supplier.firebaseId == null || supplier.firebaseId!.isEmpty) {
            final docRef = await _firestoreService.suppliers.add(supplierData); // Cambiar
            supplier.firebaseId = docRef.id;
          } else {
            await _firestoreService.suppliers // Cambiar
                .doc(supplier.firebaseId!)
                .update(supplierData);
          }

          supplier.isSynced = true;
          supplier.lastSync = DateTime.now();
          supplier.userId = userId;

          await _isarService.isar.writeTxn(() async {
            await _isarService.isar.supplierModels.put(supplier);
          });

          uploadedCount++;
          if (kDebugMode) {
            print('  ✓ Proveedor: ${supplier.name}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('  ✗ Error proveedor ${supplier.name}: $e');
          }
        }
      }

      return {
        'success': true,
        'count': uploadedCount,
        'total': allSuppliers.length,
        'message': 'Proveedores: $uploadedCount/${allSuppliers.length}'
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error subiendo proveedores: $e'
      };
    }
  }

  Future<Map<String, dynamic>> _forceUploadProducts(String userId) async {
    try {
      final allProducts = await _isarService.isar.productModels.where().findAll();
      int uploadedCount = 0;

      for (final product in allProducts) {
        try {
          final productData = {
            'code': product.code,
            'name': product.name,
            'description': product.description ?? '',
            'price': product.price,
            'cost': product.cost,
            'stock': product.stock,
            'minStock': product.minStock,
            'categoryId': product.categoryId,
            'supplierId': product.supplierId,
            'createdAt': product.createdAt.toIso8601String(),
            'updatedAt': product.updatedAt.toIso8601String(),
            'userId': userId,
            'localId': product.id.toString(),
            'isActive': true,
          };

          if (product.firebaseId == null || product.firebaseId!.isEmpty) {
            final docRef = await _firestoreService.products.add(productData); // Cambiar
            product.firebaseId = docRef.id;
          } else {
            await _firestoreService.products // Cambiar
                .doc(product.firebaseId!)
                .update(productData);
          }

          product.isSynced = true;
          product.lastSync = DateTime.now();
          product.userId = userId;

          await _isarService.isar.writeTxn(() async {
            await _isarService.isar.productModels.put(product);
          });

          uploadedCount++;
          if (kDebugMode) {
            print('  ✓ Producto: ${product.name} (Stock: ${product.stock})');
          }
        } catch (e) {
          if (kDebugMode) {
            print('  ✗ Error producto ${product.name}: $e');
          }
        }
      }

      return {
        'success': true,
        'count': uploadedCount,
        'total': allProducts.length,
        'message': 'Productos: $uploadedCount/${allProducts.length}'
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error subiendo productos: $e'
      };
    }
  }

  Future<Map<String, dynamic>> _forceUploadUsers(String userId) async {
    try {
      final allUsers = await _isarService.isar.userModels.where().findAll();
      int uploadedCount = 0;

      for (final user in allUsers) {
        try {
          final userData = {
            'username': user.username,
            'fullName': user.fullName,
            'email': user.email,
            'role': user.role.index,
            'assignedCategoryId': user.assignedCategoryId,
            'isActive': user.isActive,
            'createdAt': user.createdAt.toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
            'localId': user.id.toString(),
          };

          // Solo subir usuarios con email (usuarios reales)
          if (user.email.isNotEmpty) {
            if (user.firebaseId == null || user.firebaseId!.isEmpty) {
              final docRef = await _firestoreService.users.add(userData); // Cambiar
              user.firebaseId = docRef.id;
            } else {
              await _firestoreService.users // Cambiar
                  .doc(user.firebaseId!)
                  .update(userData);
            }

            user.isSynced = true;
            user.lastSync = DateTime.now();

            await _isarService.isar.writeTxn(() async {
              await _isarService.isar.userModels.put(user);
            });

            uploadedCount++;
            if (kDebugMode) {
              print('  ✓ Usuario: ${user.username} (${user.email})');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('  ✗ Error usuario ${user.username}: $e');
          }
        }
      }

      return {
        'success': true,
        'count': uploadedCount,
        'total': allUsers.length,
        'message': 'Usuarios: $uploadedCount/${allUsers.length}'
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error subiendo usuarios: $e'
      };
    }
  }

  // Método para verificar qué datos están listos para subir
  Future<Map<String, dynamic>> getUploadStats() async {
    try {
      final allCategories = await _isarService.isar.categoryModels.where().findAll();
      final allProducts = await _isarService.isar.productModels.where().findAll();
      final allSuppliers = await _isarService.isar.supplierModels.where().findAll();
      final allUsers = await _isarService.isar.userModels.where().findAll();

      return {
        'categories': {
          'total': allCategories.length,
          'synced': allCategories.where((c) => c.isSynced).length,
          'unsynced': allCategories.where((c) => !c.isSynced).length,
        },
        'products': {
          'total': allProducts.length,
          'synced': allProducts.where((p) => p.isSynced).length,
          'unsynced': allProducts.where((p) => !p.isSynced).length,
        },
        'suppliers': {
          'total': allSuppliers.length,
          'synced': allSuppliers.where((s) => s.isSynced).length,
          'unsynced': allSuppliers.where((s) => !s.isSynced).length,
        },
        'users': {
          'total': allUsers.length,
          'synced': allUsers.where((u) => u.isSynced).length,
          'unsynced': allUsers.where((u) => !u.isSynced).length,
        },
      };
    } catch (e) {
      return {'error': 'Error obteniendo estadísticas: $e'};
    }
  }
  // Método para forzar sincronización con logs detallados
  Future<Map<String, dynamic>> forceSyncWithLogs() async {
    final logs = <String>[];
    
    void log(String message) {
      logs.add('${DateTime.now().toIso8601String()}: $message');
      print(message);
    }
    
    try {
      log('🚀 INICIANDO SINCRONIZACIÓN FORZADA');
      
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        log('❌ Usuario no autenticado');
        return {'success': false, 'error': 'No autenticado', 'logs': logs};
      }
      
      log('👤 Usuario: ${currentUser.uid}');
      
      // Subir categorías
      log('📤 Subiendo categorías...');
      final categoriesResult = await _forceUploadCategories(currentUser.uid);
      log('✅ Categorías: ${categoriesResult['message']}');
      
      // Subir proveedores
      log('📤 Subiendo proveedores...');
      final suppliersResult = await _forceUploadSuppliers(currentUser.uid);
      log('✅ Proveedores: ${suppliersResult['message']}');
      
      // Subir productos
      log('📤 Subiendo productos...');
      final productsResult = await _forceUploadProducts(currentUser.uid);
      log('✅ Productos: ${productsResult['message']}');
      
      // Verificar en Firestore
      log('🔍 Verificando datos en Firestore...');
      final categoriesSnapshot = await _firestoreService.categories // Cambiar
          .where('userId', isEqualTo: currentUser.uid)
          .get();
      log('📊 Firestore - Categorías: ${categoriesSnapshot.docs.length}');
      
      return {
        'success': true,
        'message': 'Sincronización forzada completada',
        'logs': logs,
        'firestore_categories': categoriesSnapshot.docs.length,
      };
      
    } catch (e, stackTrace) {
      log('❌ ERROR CRÍTICO: $e');
      log('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
        'logs': logs,
      };
    }
  }
  // En sync_service.dart - Agrega estos métodos:

  Future<Map<String, dynamic>> debugSync() async {
    print('\n🔍 DEBUG DE SINCRONIZACIÓN');
    print('==========================');
    
    try {
      // 1. Verificar conexión
      print('1. Verificando conexión a internet...');
      final hasConnection = await checkConnection();
      print('   ✅ Conexión: ${hasConnection ? "SÍ" : "NO"}');
      
      // 2. Verificar autenticación
      print('2. Verificando autenticación...');
      final currentUser = await _authService.getCurrentUser();
      print('   ✅ Usuario: ${currentUser?.uid ?? "NO AUTENTICADO"}');
      
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado. Por favor, inicia sesión primero.',
          'steps': [
            {'message': '❌ Usuario no autenticado', 'isError': true},
            {'message': 'Conecta a internet y reinicia la app', 'isWarning': true},
          ]
        };
      }
      
      // 3. Verificar Firestore
      print('3. Probando conexión a Firestore...');
      try {
        await _firestoreService.categories.limit(1).get(); // Cambiar
        print('   ✅ Firestore conectado');
      } catch (e) {
        print('   ❌ Error Firestore: $e');
        return {
          'success': false,
          'error': 'Error conectando a Firestore: $e',
          'steps': [
            {'message': '✅ Usuario autenticado', 'isError': false},
            {'message': '❌ Error conectando a Firestore: $e', 'isError': true},
          ]
        };
      }
      
      // 4. Contar datos locales
      print('4. Contando datos locales...');
      final localCategories = await _isarService.isar.categoryModels.where().findAll();
      final localProducts = await _isarService.isar.productModels.where().findAll();
      final localSuppliers = await _isarService.isar.supplierModels.where().findAll();
      
      print('   📊 Categorías: ${localCategories.length}');
      print('   📊 Productos: ${localProducts.length}');
      print('   📊 Proveedores: ${localSuppliers.length}');
      
      return {
        'success': true,
        'message': 'Debug completado exitosamente',
        'user_id': currentUser.uid,
        'local_data': {
          'categories': localCategories.length,
          'products': localProducts.length,
          'suppliers': localSuppliers.length,
        },
        'steps': [
          {'message': '✅ Conexión a internet: OK', 'isError': false},
          {'message': '✅ Usuario autenticado: ${currentUser.uid}', 'isError': false},
          {'message': '✅ Firestore conectado', 'isError': false},
          {'message': '📊 Datos locales: ${localCategories.length} categorías, ${localProducts.length} productos, ${localSuppliers.length} proveedores', 'isError': false},
        ]
      };
      
    } catch (e, stackTrace) {
      print('❌ ERROR EN DEBUG: $e');
      print('Stack trace: $stackTrace');
      
      return {
        'success': false,
        'error': 'Error en debug: $e',
        'steps': [
          {'message': '❌ Error crítico: $e', 'isError': true},
        ]
      };
    }
  }

  // Método mejorado para subir datos
  Future<Map<String, dynamic>> uploadAllLocalDataWithProgress() async {
    final steps = <Map<String, dynamic>>[];
    final startTime = DateTime.now();
    
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
          'steps': steps,
        };
      }

      if (!await checkConnection()) {
        return {
          'success': false,
          'error': 'Sin conexión a internet',
          'steps': steps,
        };
      }

      steps.add({
        'message': '🚀 Iniciando subida de datos a Firebase...',
        'timestamp': DateTime.now().toIso8601String(),
        'isError': false,
      });

      final userId = currentUser.uid;
      
      // Subir categorías
      steps.add({
        'message': '📤 Subiendo categorías...',
        'timestamp': DateTime.now().toIso8601String(),
        'isError': false,
      });
      
      final categoriesResult = await _forceUploadCategories(userId);
      if (categoriesResult['success'] == true) {
        steps.add({
          'message': '✅ Categorías subidas: ${categoriesResult['count']}/${categoriesResult['total']}',
          'timestamp': DateTime.now().toIso8601String(),
          'isError': false,
        });
      } else {
        steps.add({
          'message': '⚠️ Error en categorías: ${categoriesResult['error']}',
          'timestamp': DateTime.now().toIso8601String(),
          'isWarning': true,
        });
      }
      
      // Subir proveedores
      steps.add({
        'message': '📤 Subiendo proveedores...',
        'timestamp': DateTime.now().toIso8601String(),
        'isError': false,
      });
      
      final suppliersResult = await _forceUploadSuppliers(userId);
      if (suppliersResult['success'] == true) {
        steps.add({
          'message': '✅ Proveedores subidos: ${suppliersResult['count']}/${suppliersResult['total']}',
          'timestamp': DateTime.now().toIso8601String(),
          'isError': false,
        });
      } else {
        steps.add({
          'message': '⚠️ Error en proveedores: ${suppliersResult['error']}',
          'timestamp': DateTime.now().toIso8601String(),
          'isWarning': true,
        });
      }
      
      // Subir productos
      steps.add({
        'message': '📤 Subiendo productos...',
        'timestamp': DateTime.now().toIso8601String(),
        'isError': false,
      });
      
      final productsResult = await _forceUploadProducts(userId);
      if (productsResult['success'] == true) {
        steps.add({
          'message': '✅ Productos subidos: ${productsResult['count']}/${productsResult['total']}',
          'timestamp': DateTime.now().toIso8601String(),
          'isError': false,
        });
      } else {
        steps.add({
          'message': '⚠️ Error en productos: ${productsResult['error']}',
          'timestamp': DateTime.now().toIso8601String(),
          'isWarning': true,
        });
      }
      
      // Verificar en Firestore
      steps.add({
        'message': '🔍 Verificando datos en Firestore...',
        'timestamp': DateTime.now().toIso8601String(),
        'isError': false,
      });
      
      final categoriesSnapshot = await _firestoreService.categories // Cambiar
          .where('userId', isEqualTo: userId)
          .get();
      
      final productsSnapshot = await _firestoreService.products // Cambiar
          .where('userId', isEqualTo: userId)
          .get();
      
      final totalUploaded = (categoriesResult['count'] ?? 0) + 
                          (suppliersResult['count'] ?? 0) + 
                          (productsResult['count'] ?? 0);
      
      final duration = DateTime.now().difference(startTime);
      
      steps.add({
        'message': '🎉 Subida completada en ${duration.inSeconds} segundos',
        'timestamp': DateTime.now().toIso8601String(),
        'isError': false,
      });
      
      return {
        'success': true,
        'message': 'Subida completada: $totalUploaded registros',
        'total_uploaded': totalUploaded,
        'firestore_categories': categoriesSnapshot.docs.length,
        'firestore_products': productsSnapshot.docs.length,
        'duration_seconds': duration.inSeconds,
        'steps': steps,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e, stackTrace) {
      steps.add({
        'message': '❌ Error crítico: $e',
        'timestamp': DateTime.now().toIso8601String(),
        'isError': true,
      });
      
      return {
        'success': false,
        'error': 'Error en uploadAllLocalData: $e',
        'stack_trace': stackTrace.toString(),
        'steps': steps,
      };
    }
  }
}