// presentation/cubits/auth_cubit.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockmaster/data/repositories/auth_repository.dart';
import 'package:stockmaster/data/models/user_model.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  UserModel? _currentUser;
  
  AuthCubit(this._authRepository) : super(AuthInitial());
  
  factory AuthCubit.withRepository({required AuthRepository authRepository}) {
    return AuthCubit(authRepository);
  }
  
  UserModel? get currentUser => _currentUser;

  int? get assignedCategoryId => _currentUser?.assignedCategoryId;
  
  // GETTERS CORREGIDOS
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isManager => _currentUser?.role == UserRole.manager;
  bool get isWorker => _currentUser?.role == UserRole.worker;
  
  Future<void> initializeSampleUsers() async {
    await _authRepository.initializeSampleUsers();
  }
  
  Future<void> login(String username, String password) async {
    emit(AuthLoading());
    
    try {
      final user = await _authRepository.login(username, password);
      
      if (user != null) {
        _currentUser = user;
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Usuario o contraseña incorrectos'));
      }
    } catch (e) {
      emit(AuthError('Error: $e'));
    }
  }
  
  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    emit(AuthInitial());
  }
  
  // Métodos de verificación de permisos
  bool canViewAllCategories() {
    return _currentUser?.role == UserRole.admin;
  }
  
  bool canEditCategory() {
    return _currentUser?.role == UserRole.admin || 
           _currentUser?.role == UserRole.manager;
  }
  
  bool canViewCategory(int categoryId) {
    if (_currentUser == null) return false;
    
    switch (_currentUser!.role) {
      case UserRole.admin:
        return true;
      case UserRole.manager:
      case UserRole.worker:
        return _currentUser!.assignedCategoryId == categoryId;
    }
  }
  
  bool canEditProduct() {
    return _currentUser?.role == UserRole.admin || 
           _currentUser?.role == UserRole.manager;
  }
  
  bool canDeleteProduct() {
    return _currentUser?.role == UserRole.admin;
  }
  
  // Obtener categorías permitidas para el usuario
  List<int> getAllowedCategoryIds() {
    if (_currentUser == null) return [];
    
    if (_currentUser!.role == UserRole.admin) {
      return [];  // Lista vacía significa todas las categorías
    } else {
      return _currentUser!.assignedCategoryId != null 
          ? [_currentUser!.assignedCategoryId!]
          : [];
    }
  }

  canEditCategories() {}
}