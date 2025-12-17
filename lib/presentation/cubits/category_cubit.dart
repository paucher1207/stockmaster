// presentation/cubits/category_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockmaster/data/models/category_model.dart';
import 'package:stockmaster/data/repositories/category_repository.dart';

part 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepository _categoryRepository;
  List<int> _allowedCategoryIds = [];
  
  CategoryCubit({required CategoryRepository categoryRepository})
      : _categoryRepository = categoryRepository,
        super(CategoryInitial());

  // NUEVO: Configurar categorías permitidas
  void setAllowedCategoryIds(List<int> allowedCategoryIds) {
    _allowedCategoryIds = allowedCategoryIds;
  }

  // MODIFICADO: Cargar categorías filtradas
  Future<void> loadCategories() async {
    emit(CategoryLoading());
    try {
      final allCategories = await _categoryRepository.getAllCategories();
      
      // Filtrar categorías según permisos
      List<CategoryModel> filteredCategories;
      
      if (_allowedCategoryIds.isEmpty) {
        filteredCategories = allCategories; // Admin: todas
      } else {
        filteredCategories = allCategories
            .where((category) => _allowedCategoryIds.contains(category.id))
            .toList();
      }
      
      emit(CategoryLoaded(categories: filteredCategories));
    } catch (e) {
      emit(CategoryError(message: 'Error al cargar categorías: $e'));
    }
  }

  // MODIFICADO: Agregar categoría con verificación de permisos
  Future<void> addCategory(CategoryModel category) async {
    try {
      // Si no es admin, no puede agregar categorías nuevas
      if (_allowedCategoryIds.isNotEmpty) {
        emit(const CategoryError(message: 'No tienes permisos para agregar categorías'));
        return;
      }
      
      await _categoryRepository.createCategory(category);
      await loadCategories();
    } catch (e) {
      emit(CategoryError(message: 'Error al agregar categoría: $e'));
    }
  }

  // MODIFICADO: Actualizar categoría con verificación de permisos
  Future<void> updateCategory(CategoryModel category) async {
    try {
      // Verificar permisos para esta categoría
      if (_allowedCategoryIds.isNotEmpty && !_allowedCategoryIds.contains(category.id)) {
        emit(const CategoryError(message: 'No tienes permisos para editar esta categoría'));
        return;
      }
      
      await _categoryRepository.updateCategory(category);
      await loadCategories();
    } catch (e) {
      emit(CategoryError(message: 'Error al actualizar categoría: $e'));
    }
  }

  // MODIFICADO: Eliminar categoría con verificación de permisos
  Future<void> deleteCategory(int id) async {
    try {
      // Verificar permisos para esta categoría
      if (_allowedCategoryIds.isNotEmpty && !_allowedCategoryIds.contains(id)) {
        emit(const CategoryError(message: 'No tienes permisos para eliminar esta categoría'));
        return;
      }
      
      await _categoryRepository.deleteCategory(id);
      await loadCategories();
    } catch (e) {
      emit(CategoryError(message: 'Error al eliminar categoría: $e'));
    }
  }

  // MODIFICADO: Buscar categorías filtradas
  Future<void> searchCategories(String query) async {
    if (query.isEmpty) {
      await loadCategories();
      return;
    }

    emit(CategoryLoading());
    try {
      final categories = await _categoryRepository.searchCategories(query);
      
      // Filtrar resultados según permisos
      List<CategoryModel> filteredCategories;
      
      if (_allowedCategoryIds.isEmpty) {
        filteredCategories = categories;
      } else {
        filteredCategories = categories
            .where((category) => _allowedCategoryIds.contains(category.id))
            .toList();
      }
      
      emit(CategoryLoaded(categories: filteredCategories));
    } catch (e) {
      emit(CategoryError(message: 'Error al buscar categorías: $e'));
    }
  }

  // MODIFICADO: Cargar categorías de ejemplo solo para admin
  Future<void> loadSampleCategories() async {
    // Solo admin puede cargar datos de ejemplo
    if (_allowedCategoryIds.isNotEmpty) {
      emit(const CategoryError(message: 'Solo administradores pueden cargar datos de ejemplo'));
      return;
    }
    
    emit(CategoryLoading());
    try {
      await _categoryRepository.initializeSampleCategories();
      await loadCategories();
    } catch (e) {
      emit(CategoryError(message: 'Error al cargar categorías de ejemplo: $e'));
    }
  }
  
  // NUEVO: Obtener categoría específica con verificación de permisos
  Future<CategoryModel?> getCategoryById(int id) async {
    try {
      final allCategories = await _categoryRepository.getAllCategories();
      final category = allCategories.firstWhere((cat) => cat.id == id, orElse: () => CategoryModel());
      
      if (category.id == 0) return null;
      
      // Verificar permisos
      if (_allowedCategoryIds.isNotEmpty && !_allowedCategoryIds.contains(category.id)) {
        return null;
      }
      
      return category;
    } catch (e) {
      return null;
    }
  }
}