// domain/entities/dashboard_stats.dart
import 'package:stockmaster/data/models/product_model.dart';
import 'package:stockmaster/data/models/user_model.dart';

class DashboardStats {
  final int totalProducts;
  final int totalCategories;
  final int totalSuppliers;
  final int lowStockProducts;
  final int outOfStockProducts;
  final int criticalStockProducts;
  final double totalInventoryValue;
  final double totalInventoryCost;
  final double profitMargin; // AGREGAR ESTE CAMPO
  final int recentProductsCount;
  final UserModel? user;
  final String userScope; // AGREGAR ESTE CAMPO
  final List<ProductModel> filteredProducts;
  final List<ProductModel> recentLowStockProducts;
  final List<ProductModel> recentOutOfStockProducts;
  final List<ProductModel> recentCriticalStockProducts;
  final List<ProductModel> recentAddedProducts;
  final List<ProductModel> topValueProducts;
  final List<ProductModel> latestLowStockProducts;
  final List<ProductModel> latestAddedProducts;
  final List<ProductModel> latestCriticalProducts;

  const DashboardStats({
    required this.totalProducts,
    required this.totalCategories,
    required this.totalSuppliers,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.criticalStockProducts,
    required this.totalInventoryValue,
    required this.totalInventoryCost,
    required this.profitMargin, // AGREGAR
    required this.recentProductsCount,
    this.user,
    required this.userScope, // AGREGAR
    required this.filteredProducts,
    required this.recentLowStockProducts,
    required this.recentOutOfStockProducts,
    required this.recentCriticalStockProducts,
    required this.recentAddedProducts,
    required this.topValueProducts,
    required this.latestLowStockProducts,
    required this.latestAddedProducts,
    required this.latestCriticalProducts,
  });

  // Getter para compatibilidad con código existente
  String get profitMarginPercentage => '${profitMargin.toStringAsFixed(1)}%';
}