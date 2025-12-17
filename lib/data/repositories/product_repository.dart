// ignore_for_file: avoid_print

import 'package:isar/isar.dart';
import 'package:stockmaster/data/isar/isar_service.dart';
import 'package:stockmaster/data/models/product_model.dart';
import 'package:stockmaster/data/models/stock_movement_model.dart';

class ProductRepository {
  final IsarService _isarService;

  ProductRepository(this._isarService);

  // ========== MÉTODOS BÁSICOS ==========

  Future<List<ProductModel>> getAllProducts() async {
    return await _isarService.isar.productModels.where().findAll();
  }

  Future<List<ProductModel>> getProductsByAllowedCategoryIds(List<int> allowedCategoryIds) async {
    if (allowedCategoryIds.isEmpty) {
      // Admin ve todos los productos
      return await getAllProducts();
    } else {
      // Filtrar productos por categorías permitidas
      final allProducts = await getAllProducts();
      return allProducts
          .where((product) => allowedCategoryIds.contains(product.categoryId))
          .toList();
    }
  }

  Future<List<ProductModel>> getProductsByCategoryId(int categoryId, List<int> allowedCategoryIds) async {
    if (allowedCategoryIds.isNotEmpty && !allowedCategoryIds.contains(categoryId)) {
      // El usuario no tiene permiso para ver esta categoría
      return [];
    }
    
    final allProducts = await getAllProducts();
    return allProducts
        .where((product) => product.categoryId == categoryId)
        .toList();
  }

  Future<bool> isProductInAllowedCategories(int productId, List<int> allowedCategoryIds) async {
    final product = await _isarService.isar.productModels.get(productId);
    if (product == null) return false;
    
    if (allowedCategoryIds.isEmpty) return true; // Admin
    
    return allowedCategoryIds.contains(product.categoryId);
  }

  Future<ProductModel?> getProductById(int id) async {
    final isar = _isarService.isar;
    return await isar.productModels.get(id);
  }

  Future<ProductModel?> getProductByCode(String code) async {
    final isar = _isarService.isar;
    return await isar.productModels
        .where()
        .filter()
        .codeEqualTo(code)
        .findFirst();
  }

  Future<int> createProduct(ProductModel product) async {
    final isar = _isarService.isar;
    
    // Verificar código único
    final existing = await getProductByCode(product.code);
    if (existing != null) {
      throw Exception('Código ya existe: ${product.code}');
    }

    final now = DateTime.now();
    product.createdAt = now;
    product.updatedAt = now;

    return await isar.writeTxn(() async {
      return await isar.productModels.put(product);
    });
  }

  Future<bool> updateProduct(ProductModel product) async {
    final isar = _isarService.isar;
    
    // Verificar código único (excluyendo el producto actual)
    final existing = await getProductByCode(product.code);
    if (existing != null && existing.id != product.id) {
      throw Exception('Código ya existe: ${product.code}');
    }

    product.updatedAt = DateTime.now();

    final result = await isar.writeTxn(() async {
      return await isar.productModels.put(product);
    });
    
    return result > 0;
  }

  Future<bool> deleteProduct(int id) async {
    final isar = _isarService.isar;
    return await isar.writeTxn(() async {
      return await isar.productModels.delete(id);
    });
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    if (query.isEmpty) return await getAllProducts();
    
    final products = await getAllProducts();
    final lowerQuery = query.toLowerCase();
    
    return products.where((product) {
      return product.name.toLowerCase().contains(lowerQuery) ||
             product.code.toLowerCase().contains(lowerQuery) ||
             (product.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  Future<List<ProductModel>> getLowStockProducts() async {
    final products = await getAllProducts();
    return products.where((p) => p.stock <= p.minStock && p.stock > 0).toList();
  }

  Future<List<ProductModel>> getOutOfStockProducts() async {
    final products = await getAllProducts();
    return products.where((p) => p.stock == 0).toList();
  }

  Future<List<ProductModel>> getProductsByCategory(int categoryId) async {
    final products = await getAllProducts();
    return products.where((p) => p.categoryId == categoryId).toList();
  }

  Future<bool> codeExists(String code, {int? excludeProductId}) async {
    final existing = await getProductByCode(code);
    return existing != null && existing.id != excludeProductId;
  }

  // ========== MÉTODOS DE MOVIMIENTOS ==========

  Future<void> updateStockWithMovement({
    required int productId,
    required String movementType,
    required int quantity,
    required String reason,
    required String reference,
    required int userId,
    required String userName,
  }) async {
    final isar = _isarService.isar;
    
    await isar.writeTxn(() async {
      final product = await isar.productModels.get(productId);
      if (product == null) throw Exception('Producto no encontrado');

      final previousStock = product.stock;
      int newStock = previousStock;
      int movementQuantity = quantity;

      switch (movementType) {
        case 'entry':
          newStock += quantity;
          break;
        case 'exit':
          if (previousStock < quantity) {
            throw Exception('Stock insuficiente: $previousStock');
          }
          newStock -= quantity;
          break;
        case 'adjustment':
          if (quantity < 0) throw Exception('Stock no puede ser negativo');
          movementQuantity = quantity - previousStock;
          newStock = quantity;
          break;
      }

      // Actualizar producto
      product.stock = newStock;
      product.updatedAt = DateTime.now();
      await isar.productModels.put(product);

      // Crear movimiento
      final movement = StockMovementModel()
        ..date = DateTime.now()
        ..type = movementType
        ..quantity = movementQuantity
        ..reason = reason
        ..reference = reference
        ..productId = productId
        ..userId = userId
        ..userName = userName
        ..previousStock = previousStock
        ..newStock = newStock;

      await isar.stockMovementModels.put(movement);
    });
  }

  Future<List<StockMovementModel>> getProductMovementHistory(int productId) async {
    final isar = _isarService.isar;
    final movements = await isar.stockMovementModels
        .where()
        .filter()
        .productIdEqualTo(productId)
        .findAll();
    
    movements.sort((a, b) => b.date.compareTo(a.date));
    return movements;
  }

  // ========== MÉTODOS DE ESTADÍSTICAS ==========

  Future<double> getTotalInventoryValue() async {
    final products = await getAllProducts();
    double total = 0.0;
    for (final product in products) {
      total += product.price * product.stock;
    }
    return total;
  }

  Future<double> getTotalInventoryCost() async {
    final products = await getAllProducts();
    double total = 0.0;
    for (final product in products) {
      total += product.cost * product.stock;
    }
    return total;
  }

Future<void> initializeSampleData() async {
  try {
    // NO inicialices Isar aquí - ya está inicializado en main.dart
    
    // Obtener la instancia de Isar
    final isar = _isarService.isar;
    
    // Verificar si ya existen los productos por código (mejor que solo contar)
    final existingLaptop = await getProductByCode('LAP-001');
    final existingMonitor = await getProductByCode('MON-001');
    
    // Solo crear si no existen
    if (existingLaptop == null || existingMonitor == null) {
      final sampleProducts = [
        ProductModel()
          ..code = 'LAP-001'
          ..name = 'Laptop Dell'
          ..description = 'Laptop Dell Inspiron 15'
          ..price = 899.99
          ..cost = 650.00
          ..stock = 5
          ..minStock = 2
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now(),
        
        ProductModel()
          ..code = 'MON-001'
          ..name = 'Monitor Samsung'
          ..description = 'Monitor 24 pulgadas Full HD'
          ..price = 199.99
          ..cost = 150.00
          ..stock = 8
          ..minStock = 3
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now(),
      ];

      await isar.writeTxn(() async {
        for (final product in sampleProducts) {
          await isar.productModels.put(product);
        }
      });
      
      print('Datos de ejemplo cargados correctamente');
    } else {
      print('Los datos de ejemplo ya existen, se omiten');
    }
  } catch (e) {
    print('Error al inicializar datos de ejemplo: $e');
    // No relanzar la excepción - solo loggear
  }
}


}
