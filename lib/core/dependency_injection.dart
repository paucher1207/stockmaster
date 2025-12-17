import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:stockmaster/data/isar/isar_service.dart';
import 'package:stockmaster/data/firebase/firebase_auth_service.dart';
import 'package:stockmaster/data/firebase/firestore_service.dart';
import 'package:stockmaster/data/firebase/sync_service.dart';
import 'package:stockmaster/data/repositories/product_repository.dart';
import 'package:stockmaster/data/repositories/category_repository.dart';
import 'package:stockmaster/data/repositories/supplier_repository.dart';
import 'package:stockmaster/data/repositories/stock_movement_repository.dart';
import 'package:stockmaster/data/repositories/auth_repository.dart';
import 'package:stockmaster/presentation/cubits/product_cubit.dart';
import 'package:stockmaster/presentation/cubits/category_cubit.dart';
import 'package:stockmaster/presentation/cubits/supplier_cubit.dart';
import 'package:stockmaster/presentation/cubits/auth_cubit.dart';
import 'package:stockmaster/presentation/cubits/stock_movement_cubit.dart';
import 'package:stockmaster/presentation/cubits/dashboard_cubit.dart';
import 'package:stockmaster/presentation/cubits/sync_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  if (kDebugMode) {
    print('Inicializando IsarService...');
  }
  
  // 1. Inicializar IsarService (solo una vez)
  final isarService = IsarService();
  await isarService.initialize();
  
  // 2. Registrar IsarService como singleton
  if (!getIt.isRegistered<IsarService>()) {
    getIt.registerSingleton<IsarService>(isarService);
  }
  if (kDebugMode) {
    print('✓ IsarService registrado');
  }

  // 3. Registrar servicios de Firebase (solo una vez)
  if (kDebugMode) {
    print('Registrando servicios de Firebase...');
  }
  
  if (!getIt.isRegistered<FirebaseAuthService>()) {
    getIt.registerSingleton<FirebaseAuthService>(FirebaseAuthService());
  }
  
  if (!getIt.isRegistered<FirestoreService>()) {
    getIt.registerSingleton<FirestoreService>(FirestoreService());
  }
  if (kDebugMode) {
    print('✓ Servicios de Firebase registrados');
  }

  // 4. Registrar SyncService (SOLO UNA VEZ)
  if (kDebugMode) {
    print('Registrando SyncService...');
  }
  if (!getIt.isRegistered<SyncService>()) {
    getIt.registerSingleton<SyncService>(SyncService(
      isarService: getIt<IsarService>(),
      authService: getIt<FirebaseAuthService>(),
      firestoreService: getIt<FirestoreService>(), // Añadir esta línea
    ));
  }
  if (kDebugMode) {
    print('✓ SyncService registrado');
  }

  // 5. Registrar Repositories
  if (kDebugMode) {
    print('Registrando repositorios...');
  }
  
  // ProductRepository
  if (!getIt.isRegistered<ProductRepository>()) {
    getIt.registerFactory<ProductRepository>(
      () => ProductRepository(getIt<IsarService>()),
    );
  }
  
  // CategoryRepository
  if (!getIt.isRegistered<CategoryRepository>()) {
    getIt.registerFactory<CategoryRepository>(
      () => CategoryRepository(getIt<IsarService>()),
    );
  }
  
  // SupplierRepository
  if (!getIt.isRegistered<SupplierRepository>()) {
    getIt.registerFactory<SupplierRepository>(
      () => SupplierRepository(getIt<IsarService>()),
    );
  }
  
  // StockMovementRepository
  if (!getIt.isRegistered<StockMovementRepository>()) {
    getIt.registerFactory<StockMovementRepository>(
      () => StockMovementRepository(getIt<IsarService>()),
    );
  }
  
  // AuthRepository - ACTUALIZADO para incluir FirestoreService
  if (!getIt.isRegistered<AuthRepository>()) {
    getIt.registerFactory<AuthRepository>(
      () => AuthRepository(
        isarService: getIt<IsarService>(),
        firebaseAuthService: getIt<FirebaseAuthService>(),
        syncService: getIt<SyncService>(),
        firestoreService: getIt<FirestoreService>(), // Añadido
      ),
    );
  }
  if (kDebugMode) {
    print('✓ Repositorios registrados');
  }

  // 6. Registrar Cubits (siempre Factory)
  if (kDebugMode) {
    print('Registrando cubits...');
  }
  
  // AuthCubit - Constructor posicional
  if (!getIt.isRegistered<AuthCubit>()) {
    getIt.registerFactory<AuthCubit>(
      () => AuthCubit(getIt<AuthRepository>()),
    );
  }
  if (kDebugMode) {
    print('✓ AuthCubit registrado');
  }
  
  if (!getIt.isRegistered<CategoryCubit>()) {
    getIt.registerFactory<CategoryCubit>(
      () => CategoryCubit(categoryRepository: getIt<CategoryRepository>()),
    );
  }
  if (kDebugMode) {
    print('✓ CategoryCubit registrado');
  }
  
  if (!getIt.isRegistered<SupplierCubit>()) {
    getIt.registerFactory<SupplierCubit>(
      () => SupplierCubit(supplierRepository: getIt<SupplierRepository>()),
    );
  }
  if (kDebugMode) {
    print('✓ SupplierCubit registrado');
  }
  
  if (!getIt.isRegistered<ProductCubit>()) {
    getIt.registerFactory<ProductCubit>(
      () => ProductCubit(productRepository: getIt<ProductRepository>()),
    );
  }
  if (kDebugMode) {
    print('✓ ProductCubit registrado');
  }
  
  if (!getIt.isRegistered<DashboardCubit>()) {
    getIt.registerFactory<DashboardCubit>(
      () => DashboardCubit(
        productRepository: getIt<ProductRepository>(),
        categoryRepository: getIt<CategoryRepository>(),
        supplierRepository: getIt<SupplierRepository>(),
      ),
    );
  }
  if (kDebugMode) {
    print('✓ DashboardCubit registrado');
  }
  
  if (!getIt.isRegistered<StockMovementCubit>()) {
    getIt.registerFactory<StockMovementCubit>(
      () => StockMovementCubit(
        movementRepository: getIt<StockMovementRepository>(),
        productRepository: getIt<ProductRepository>(),
      ),
    );
  }
  if (kDebugMode) {
    print('✓ StockMovementCubit registrado');
  }

  // 7. SyncCubit (SOLO UNA VEZ)
  if (!getIt.isRegistered<SyncCubit>()) {
    getIt.registerFactory<SyncCubit>(
      () => SyncCubit(getIt<SyncService>()),
    );
  }
  if (kDebugMode) {
    print('✓ SyncCubit registrado');
  }

  // 8. Cargar datos de ejemplo SOLO si no hay usuario autenticado
  if (kDebugMode) {
    print('Verificando modo de operación...');
  }
  final authService = getIt<FirebaseAuthService>();
  final currentUser = await authService.getCurrentUser();
  
  if (currentUser == null) {
    if (kDebugMode) {
      print('Usuario no autenticado, cargando datos de ejemplo...');
    }
    await _loadSampleData();
    if (kDebugMode) {
      print('✓ Datos de ejemplo cargados');
    }
  } else {
    if (kDebugMode) {
      print('✓ Usuario autenticado: ${currentUser.uid}');
    }
    // Verificar si Firestore necesita inicialización
    try {
      final authRepo = getIt<AuthRepository>();
      await authRepo.updateExistingUsersWithEmails();
    } catch (e) {
      if (kDebugMode) {
        print('⚠ Error actualizando usuarios: $e');
      }
    }
  }
}

Future<void> _loadSampleData() async {
  try {
    if (kDebugMode) {
      print('  - Cargando productos de ejemplo...');
    }
    final productRepo = getIt<ProductRepository>();
    await productRepo.initializeSampleData();
    
    if (kDebugMode) {
      print('  - Cargando categorías de ejemplo...');
    }
    final categoryRepo = getIt<CategoryRepository>();
    await categoryRepo.initializeSampleCategories();
    
    if (kDebugMode) {
      print('  - Cargando proveedores de ejemplo...');
    }
    final supplierRepo = getIt<SupplierRepository>();
    await supplierRepo.initializeSampleData();
    
    if (kDebugMode) {
      print('  - Cargando usuarios de ejemplo...');
    }
    final authRepo = getIt<AuthRepository>();
    await authRepo.initializeSampleUsers();
    
    // Inicializar usuarios en Firestore también
    await authRepo.initializeFirestoreUsers();
    
    if (kDebugMode) {
      print('✓ Todos los datos de ejemplo cargados exitosamente');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠ Error cargando datos de ejemplo: $e');
    }
  }
}