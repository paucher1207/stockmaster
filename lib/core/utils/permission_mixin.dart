// core/utils/permission_mixin.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockmaster/presentation/cubits/auth_cubit.dart';

mixin PermissionMixin {
  // Obtener AuthCubit desde el contexto
  AuthCubit? _getAuthCubit(BuildContext context) {
    try {
      return context.read<AuthCubit>();
    } catch (_) {
      return null;
    }
  }
  
  // Verificar si el usuario está autenticado
  bool isAuthenticated(BuildContext context) {
    final authCubit = _getAuthCubit(context);
    return authCubit?.currentUser != null;
  }
  
  // Verificar si es administrador
  bool isAdmin(BuildContext context) {
    return _getAuthCubit(context)?.isAdmin ?? false;
  }
  
  // Verificar si puede ver una categoría
  bool canViewCategory(BuildContext context, int? categoryId) {
    return _getAuthCubit(context)?.canViewCategory(categoryId!) ?? false;
  }
  
  // Verificar si puede editar productos
  bool canEditProducts(BuildContext context) {
    return _getAuthCubit(context)?.canEditProduct() ?? false;
  }
  
  // Verificar si puede editar categorías
  bool canEditCategories(BuildContext context) {
    return _getAuthCubit(context)?.canEditCategories() ?? false;
  }
  
  // Obtener categoría asignada del usuario
  int? getUserAssignedCategory(BuildContext context) {
    return _getAuthCubit(context)?.assignedCategoryId;
  }
  
  // Obtener lista de categorías permitidas
  List<int> getAllowedCategoryIds(BuildContext context) {
    return _getAuthCubit(context)?.getAllowedCategoryIds() ?? [];
  }
  
  // Mostrar error si no tiene permisos
  void showPermissionError(BuildContext context, {String? message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'No tienes permisos para realizar esta acción'),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  // Verificar permisos antes de navegar
  bool checkPermissionBeforeNavigate(BuildContext context, {required bool requiresAdmin, required bool requiresEdit}) {
    final authCubit = _getAuthCubit(context);
    
    if (authCubit?.currentUser == null) {
      showPermissionError(context, message: 'Debes iniciar sesión');
      return false;
    }
    
    if (requiresAdmin && !(authCubit?.isAdmin ?? false)) {
      showPermissionError(context, message: 'Solo administradores pueden acceder');
      return false;
    }
    
    if (requiresEdit && !(authCubit?.canEditProduct() ?? false)) {
      showPermissionError(context, message: 'No tienes permisos para editar');
      return false;
    }
    
    return true;
  }
}