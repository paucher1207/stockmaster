// presentation/cubits/dashboard_cubit.dart - VERSIÓN CORREGIDA
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockmaster/data/models/category_model.dart';
import 'package:stockmaster/data/models/product_model.dart';
import 'package:stockmaster/data/models/supplier_model.dart';
import 'package:stockmaster/data/models/user_model.dart';
import 'package:stockmaster/data/repositories/product_repository.dart';
import 'package:stockmaster/data/repositories/category_repository.dart';
import 'package:stockmaster/data/repositories/supplier_repository.dart';
import 'package:stockmaster/domain/entities/dashboard_stats.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final ProductRepository _productRepository;
  final CategoryRepository _categoryRepository;
  final SupplierRepository _supplierRepository;
  List<int> _allowedCategoryIds = [];
  UserModel? _currentUser;

  DashboardCubit({
    required ProductRepository productRepository,
    required CategoryRepository categoryRepository,
    required SupplierRepository supplierRepository,
  })  : _productRepository = productRepository,
        _categoryRepository = categoryRepository,
        _supplierRepository = supplierRepository,
        super(DashboardInitial());

  // Configurar usuario actual y categorías permitidas
  void setUserData(UserModel user, List<int> allowedCategoryIds) {
    _currentUser = user;
    _allowedCategoryIds = allowedCategoryIds;
  }

  Future<void> loadDashboardData() async { // ELIMINAR EL PARÁMETRO
    emit(DashboardLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Obtener todos los datos
      final allProducts = await _productRepository.getAllProducts();
      final allCategories = await _categoryRepository.getAllCategories();
      final allSuppliers = await _supplierRepository.getAllSuppliers();

      // Filtrar datos según el rol del usuario
      List<ProductModel> filteredProducts = _filterProducts(allProducts);
      List<CategoryModel> filteredCategories = _filterCategories(allCategories);

      // Calcular estadísticas
      final stats = _calculateStats(
        filteredProducts, 
        filteredCategories, 
        allSuppliers, 
        _currentUser
      );

      emit(DashboardLoaded(stats: stats));
    } catch (e) {
      emit(DashboardError(message: 'Error al cargar datos del dashboard: $e'));
    }
  }

  // Filtrar productos según permisos
  List<ProductModel> _filterProducts(List<ProductModel> allProducts) {
    if (_allowedCategoryIds.isEmpty) {
      return allProducts; // Admin: todos
    } else {
      return allProducts
          .where((product) => _allowedCategoryIds.contains(product.categoryId))
          .toList();
    }
  }

  // Filtrar categorías según permisos
  List<CategoryModel> _filterCategories(List<CategoryModel> allCategories) {
    if (_allowedCategoryIds.isEmpty) {
      return allCategories; // Admin: todas
    } else {
      return allCategories
          .where((category) => _allowedCategoryIds.contains(category.id))
          .toList();
    }
  }

  DashboardStats _calculateStats(
    List<ProductModel> products,
    List<CategoryModel> categories,
    List<SupplierModel> suppliers,
    UserModel? user,
  ) {
    final totalProducts = products.length;
    final totalCategories = categories.length;
    final totalSuppliers = suppliers.length;

    // Productos con stock bajo
    final lowStockProducts = products.where((p) => p.stock <= p.minStock && p.stock > 0).toList();
    
    // Productos sin stock
    final outOfStockProducts = products.where((p) => p.stock == 0).toList();

    // Productos con stock crítico (menos del 20% del mínimo)
    final criticalStockProducts = products
        .where((p) => p.minStock > 0 && p.stock < (p.minStock * 0.2))
        .toList();

    // Valor total del inventario
    double totalInventoryValue = 0;
    double totalInventoryCost = 0;
    
    
    for (var product in products) {
      totalInventoryValue += product.stock * product.price;
      totalInventoryCost += product.stock * product.cost;
    }

    // Productos recientemente agregados (últimos 7 días)
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentProducts = products
        .where((p) => p.createdAt.isAfter(weekAgo))
        .toList();

    // Calcular margen de beneficio
    final double profitMargin = totalInventoryCost > 0 
        ? ((totalInventoryValue - totalInventoryCost) / totalInventoryCost) * 100
        : 0;

    // Determinar alcance del usuario
    String userScope;
    if (user == null) {
      userScope = 'Sin acceso';
    } else if (user.role == UserRole.admin) {
      userScope = 'Acceso completo';
    } else if (user.role == UserRole.manager) {
      userScope = 'Categoría asignada';
    } else {
      userScope = 'Solo lectura';
    }

    return DashboardStats(
      totalProducts: totalProducts,
      totalCategories: totalCategories,
      totalSuppliers: totalSuppliers,
      lowStockProducts: lowStockProducts.length,
      outOfStockProducts: outOfStockProducts.length,
      criticalStockProducts: criticalStockProducts.length,
      totalInventoryValue: totalInventoryValue,
      totalInventoryCost: totalInventoryCost,
      profitMargin: profitMargin, // AHORA ESTÁ DEFINIDO
      recentProductsCount: recentProducts.length,
      user: user,
      userScope: userScope, // AHORA ESTÁ DEFINIDO
      filteredProducts: products,
      recentLowStockProducts: _getRecentLowStockProducts(products),
      recentOutOfStockProducts: _getRecentOutOfStockProducts(products),
      recentCriticalStockProducts: _getRecentCriticalStockProducts(products),
      recentAddedProducts: _getRecentAddedProducts(products),
      topValueProducts: _getTopValueProducts(products),
      latestLowStockProducts: _getLatestLowStockProducts(products),
      latestAddedProducts: _getLatestAddedProducts(products),
      latestCriticalProducts: _getLatestCriticalProducts(products),
    );
  }

  List<ProductModel> _getRecentLowStockProducts(List<ProductModel> products) {
    final lowStock = products.where((p) => p.stock <= p.minStock && p.stock > 0).toList();
    lowStock.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return lowStock.take(5).toList();
  }

  List<ProductModel> _getRecentOutOfStockProducts(List<ProductModel> products) {
    final outOfStock = products.where((p) => p.stock == 0).toList();
    outOfStock.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return outOfStock.take(5).toList();
  }

  List<ProductModel> _getRecentCriticalStockProducts(List<ProductModel> products) {
    final critical = products
        .where((p) => p.minStock > 0 && p.stock < (p.minStock * 0.2))
        .toList();
    critical.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return critical.take(5).toList();
  }

  List<ProductModel> _getRecentAddedProducts(List<ProductModel> products) {
    final recent = products.toList();
    recent.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return recent.take(5).toList();
  }

  List<ProductModel> _getTopValueProducts(List<ProductModel> products) {
    final valued = products.toList();
    valued.sort((a, b) => (b.stock * b.price).compareTo(a.stock * a.price));
    return valued.take(5).toList();
  }

  // MÉTODOS NUEVOS para obtener los últimos productos de cada tipo
  List<ProductModel> _getLatestLowStockProducts(List<ProductModel> products) {
    final lowStock = products.where((p) => p.stock <= p.minStock).toList();
    lowStock.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return lowStock.take(5).toList();
  }

  List<ProductModel> _getLatestAddedProducts(List<ProductModel> products) {
    final allProducts = List<ProductModel>.from(products);
    allProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allProducts.take(5).toList();
  }

  List<ProductModel> _getLatestCriticalProducts(List<ProductModel> products) {
    final critical = products
        .where((p) => p.minStock > 0 && p.stock < (p.minStock * 0.2))
        .toList();
    critical.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return critical.take(5).toList();
  }
}