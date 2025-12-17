// ignore_for_file: avoid_print

import 'package:isar/isar.dart';
import 'package:stockmaster/data/isar/isar_service.dart';
import 'package:stockmaster/data/models/category_model.dart';

class CategoryRepository {
  final IsarService _isarService;

  CategoryRepository(this._isarService);

  // Obtener todas las categorías
  Future<List<CategoryModel>> getAllCategories() async {
    return await _isarService.isar.categoryModels.where().findAll();
  }

  // Crear categoría
  Future<int> createCategory(CategoryModel category) async {
    final isar = _isarService.isar;
    return await isar.writeTxn(() async {
      return await isar.categoryModels.put(category);
    });
  }

  // Obtener categoría por ID
 Future<CategoryModel?> getCategoryById(int id, List<int> allowedCategoryIds) async {
    if (allowedCategoryIds.isNotEmpty && !allowedCategoryIds.contains(id)) {
      // El usuario no tiene permiso para ver esta categoría
      return null;
    }
    
    return await _isarService.isar.categoryModels.get(id);
  }

  // Actualizar categoría
  Future<void> updateCategory(CategoryModel category) async {
    final isar = _isarService.isar;
    await isar.writeTxn(() async {
      await isar.categoryModels.put(category);
    });
  }

  // Eliminar categoría
  Future<void> deleteCategory(int id) async {
    final isar = _isarService.isar;
    await isar.writeTxn(() async {
      await isar.categoryModels.delete(id);
    });
  }

  // Buscar categorías por nombre
  Future<List<CategoryModel>> getCategoriesByAllowedIds(List<int> allowedCategoryIds) async {
    if (allowedCategoryIds.isEmpty) {
      // Lista vacía significa todas las categorías (admin)
      return await getAllCategories();
    } else {
      // Filtrar solo las categorías permitidas
      final allCategories = await getAllCategories();
      return allCategories
          .where((category) => allowedCategoryIds.contains(category.id))
          .toList();
    }
  }

  
  // Inicializar categorías de ejemplo - CORREGIDO
  Future<void> initializeSampleCategories() async {
    try {
      final isar = _isarService.isar;
      
      // Verificar si ya existen las categorías por nombre
      final existingCategory1 = await _getCategoryByName('Electrónicos');
      final existingCategory2 = await _getCategoryByName('Ropa');
      final existingCategory3 = await _getCategoryByName('Hogar');
      final existingCategory4 = await _getCategoryByName('Deportes');
      final existingCategory5 = await _getCategoryByName('Libros');
      
      // Solo crear si no existen
      if (existingCategory1 == null || existingCategory2 == null || 
          existingCategory3 == null || existingCategory4 == null || 
          existingCategory5 == null) {
        
        final sampleCategories = [
          CategoryModel()
            ..name = 'Electrónicos'
            ..description = 'Dispositivos electrónicos y gadgets'
            ..createdAt = DateTime.now(),
          CategoryModel()
            ..name = 'Ropa'
            ..description = 'Prendas de vestir y accesorios'
            ..createdAt = DateTime.now(),
          CategoryModel()
            ..name = 'Hogar'
            ..description = 'Artículos para el hogar'
            ..createdAt = DateTime.now(),
          CategoryModel()
            ..name = 'Deportes'
            ..description = 'Equipamiento deportivo'
            ..createdAt = DateTime.now(),
          CategoryModel()
            ..name = 'Libros'
            ..description = 'Libros y material educativo'
            ..createdAt = DateTime.now(),
        ];

        await isar.writeTxn(() async {
          for (final category in sampleCategories) {
            await isar.categoryModels.put(category);
          }
        });
        
        print('✓ Categorías de ejemplo cargadas correctamente');
      } else {
        print('✓ Categorías de ejemplo ya existen, se omiten');
      }
    } catch (e) {
      print('⚠ Error al cargar categorías de ejemplo: $e');
    }
  }

  // Verificar si una categoría con ese nombre ya existe
  Future<bool> categoryNameExists(String name, {int? excludeCategoryId}) async {
    final isar = _isarService.isar;
    final existingCategory = await isar.categoryModels
        .where()
        .filter()
        .nameEqualTo(name)
        .findFirst();
    
    return existingCategory != null && existingCategory.id != excludeCategoryId;
  }

  // Método para obtener el conteo total de categorías
  Future<int> getCategoryCount() async {
    final isar = _isarService.isar;
    return await isar.categoryModels.count();
  }

  Future<List<CategoryModel>> searchCategories(String query) async {
    try {
      final allCategories = await getAllCategories();
      return allCategories
          .where((category) => 
              category.name.toLowerCase().contains(query.toLowerCase()) ||
              category.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      print('Error en searchCategories: $e');
      return [];
    }
  }

  // Método auxiliar para buscar categoría por nombre
  Future<CategoryModel?> _getCategoryByName(String name) async {
    final isar = _isarService.isar;
    return await isar.categoryModels
        .where()
        .filter()
        .nameEqualTo(name)
        .findFirst();
  }
}