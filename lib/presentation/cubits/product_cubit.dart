// presentation/cubits/product_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

part 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _productRepository;
  List<int> _allowedCategoryIds = [];
  
  ProductCubit({required ProductRepository productRepository})
      : _productRepository = productRepository,
        super(ProductInitial());
        
  // NUEVO: Configurar categorías permitidas
  void setAllowedCategoryIds(List<int> allowedCategoryIds) {
    _allowedCategoryIds = allowedCategoryIds;
  }
  
  // MODIFICADO: Cargar productos filtrados
  Future<void> loadProducts() async {
    emit(ProductLoading());
    try {
      final allProducts = await _productRepository.getAllProducts();
      
      // Filtrar productos según permisos
      List<ProductModel> filteredProducts;
      
      if (_allowedCategoryIds.isEmpty) {
        filteredProducts = allProducts; // Admin: todos
      } else {
        filteredProducts = allProducts
            .where((product) => _allowedCategoryIds.contains(product.categoryId))
            .toList();
      }
      
      emit(ProductLoaded(products: filteredProducts));
    } catch (e) {
      emit(ProductError(message: 'Error al cargar productos: $e'));
    }
  }

  // MODIFICADO: Agregar/actualizar producto con verificación de permisos
  Future<void> addProduct(ProductModel product) async {
    try {
      // Verificar permisos para la categoría del producto
      if (_allowedCategoryIds.isNotEmpty && !_allowedCategoryIds.contains(product.categoryId)) {
        emit(const ProductError(message: 'No tienes permisos para agregar productos en esta categoría'));
        return;
      }
      
      if (product.id == 0 || product.id == Isar.autoIncrement) {
        await _productRepository.createProduct(product);
      } else {
        await _productRepository.updateProduct(product);
      }
      await loadProducts(); // Recargar la lista
    } catch (e) {
      emit(ProductError(message: 'Error al guardar producto: $e'));
    }
  }

  // MODIFICADO: Buscar productos filtrados
  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      await loadProducts();
      return;
    }

    emit(ProductLoading());
    try {
      final products = await _productRepository.searchProducts(query);
      
      // Filtrar resultados según permisos
      List<ProductModel> filteredProducts;
      
      if (_allowedCategoryIds.isEmpty) {
        filteredProducts = products;
      } else {
        filteredProducts = products
            .where((product) => _allowedCategoryIds.contains(product.categoryId))
            .toList();
      }
      
      emit(ProductLoaded(products: filteredProducts));
    } catch (e) {
      emit(ProductError(message: 'Error al buscar productos: $e'));
    }
  }

  // MODIFICADO: Cargar datos de ejemplo solo para admin
  Future<void> loadSampleData() async {
    // Solo admin puede cargar datos de ejemplo
    if (_allowedCategoryIds.isNotEmpty) {
      emit(const ProductError(message: 'Solo administradores pueden cargar datos de ejemplo'));
      return;
    }
    
    emit(ProductLoading());
    try {
      await _productRepository.initializeSampleData();
      await loadProducts();
    } catch (e) {
      emit(ProductError(message: 'Error al cargar datos de ejemplo: $e'));
    }
  }

  // MODIFICADO: Eliminar producto con verificación de permisos
  Future<void> deleteProduct(int id) async {
    try {
      // Primero obtener el producto para verificar su categoría
      final allProducts = await _productRepository.getAllProducts();
      final product = allProducts.firstWhere((p) => p.id == id, orElse: () => ProductModel());
      
      if (product.id == 0) {
        emit(const ProductError(message: 'Producto no encontrado'));
        return;
      }
      
      // Verificar permisos para esta categoría
      if (_allowedCategoryIds.isNotEmpty && !_allowedCategoryIds.contains(product.categoryId)) {
        emit(const ProductError(message: 'No tienes permisos para eliminar este producto'));
        return;
      }
      
      await _productRepository.deleteProduct(id);
      await loadProducts();
    } catch (e) {
      emit(ProductError(message: 'Error al eliminar producto: $e'));
    }
  }
  
  // NUEVO: Obtener productos por categoría
  Future<List<ProductModel>> getProductsByCategory(int categoryId) async {
    try {
      final allProducts = await _productRepository.getAllProducts();
      return allProducts
          .where((product) => product.categoryId == categoryId)
          .toList();
    } catch (e) {
      return [];
    }
  }
}