// app.dart - VERSIÓN CORREGIDA
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stockmaster/core/dependency_injection.dart';
import 'package:stockmaster/presentation/cubits/auth_cubit.dart';
import 'package:stockmaster/presentation/cubits/category_cubit.dart';
import 'package:stockmaster/presentation/cubits/dashboard_cubit.dart';
import 'package:stockmaster/presentation/cubits/product_cubit.dart';
import 'package:stockmaster/presentation/cubits/supplier_cubit.dart';
import 'package:stockmaster/presentation/cubits/stock_movement_cubit.dart';
import 'package:stockmaster/presentation/cubits/sync_cubit.dart';
import 'package:stockmaster/presentation/pages/home_page.dart';
import 'package:stockmaster/presentation/pages/dashboard_page.dart';
import 'package:stockmaster/presentation/pages/categories_page.dart';
import 'package:stockmaster/presentation/pages/initialize_firebase_page.dart';
import 'package:stockmaster/presentation/pages/suppliers_page.dart';
import 'package:stockmaster/presentation/pages/login_page.dart';
import 'package:stockmaster/presentation/pages/product_form_page.dart';
import 'package:stockmaster/presentation/pages/category_form_page.dart';
import 'package:stockmaster/presentation/pages/supplier_form_page.dart';
import 'package:stockmaster/presentation/pages/stock_movement_form_page.dart';
import 'package:stockmaster/presentation/pages/stock_movement_history_page.dart';
import 'package:stockmaster/data/firebase/sync_service.dart';
import 'package:stockmaster/presentation/pages/sync_test_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => getIt<ProductCubit>()),
        BlocProvider(create: (context) => getIt<CategoryCubit>()),
        BlocProvider(create: (context) => getIt<SupplierCubit>()),
        BlocProvider(create: (context) => getIt<AuthCubit>()),
        BlocProvider(create: (context) => getIt<DashboardCubit>()),
        BlocProvider(create: (context) => getIt<StockMovementCubit>()),
        BlocProvider(create: (context) => getIt<SyncCubit>()),
      ],
      child: MaterialApp(
        title: 'StockMaster',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2196F3),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          cardTheme: CardThemeData(  // CORREGIDO: usar CardTheme en lugar de CardThemeData
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const _AuthWrapper(),
        // Rutas con nombre
        routes: {
          '/home': (context) => const HomePage(),
          '/dashboard': (context) => const DashboardPage(),
          '/categories': (context) => const CategoriesPage(),
          '/category-form': (context) => const CategoryFormPage(),
          '/suppliers': (context) => const SuppliersPage(),
          '/supplier-form': (context) => const SupplierFormPage(),
          '/product-form': (context) => const ProductFormPage(),
          '/stock-movement-form': (context) => const StockMovementFormPage(),
          '/stock-history': (context) => const StockMovementHistoryPage(),
          '/sync-test': (context) => const SyncTestPage(),
          '/initialize-firebase': (context) => const InitializeFirebasePage(),
        },
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Ruta no encontrada: ${settings.name}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Widget que maneja la autenticación con Firebase y cubit
class _AuthWrapper extends StatefulWidget {
  const _AuthWrapper();

  @override
  State<_AuthWrapper> createState() => __AuthWrapperState();
}

class __AuthWrapperState extends State<_AuthWrapper> {
  late Stream<User?> _authStream;
  bool _initialCheckDone = false;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
    
    // Sincronizar datos cuando se detecte un cambio de usuario
    _authStream.listen((user) async {
      if (user != null && !_initialCheckDone) {
        // Esperar un momento para que las dependencias se inicialicen
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          await getIt<SyncService>().quickSync();
        } catch (e) {
          if (kDebugMode) {
            print('Error en sincronización inicial: $e');
          }
        }
        _initialCheckDone = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (authSnapshot.hasData) {
          // Usuario autenticado en Firebase
          return BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              if (authState is AuthAuthenticated) {
                return const HomePage();
              } else if (authState is AuthLoading) {
                return const _LoadingScreen();
              } else {
                // NO LLAMAR A autoLoginWithFirebase - ese método no existe
                // Simplemente mostrar login
                return const LoginPage();
              }
            },
          );
        } else {
          // No hay usuario en Firebase, mostrar login
          return BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              if (authState is AuthAuthenticated) {
                // Usuario local (modo offline), permitir acceso
                return const HomePage();
              } else {
                return const LoginPage();
              }
            },
          );
        }
      },
    );
  }
}

// Pantalla de carga
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Cargando StockMaster...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              FirebaseAuth.instance.currentUser != null 
                ? 'Sincronizando datos...' 
                : 'Iniciando aplicación...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}