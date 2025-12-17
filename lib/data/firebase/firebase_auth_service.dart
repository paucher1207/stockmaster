// data/firebase/firebase_auth_service.dart
// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  User? get currentUser => _auth.currentUser;
  
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }
  
  // Método para login con email/password (Firebase Auth)
  Future<User?> loginWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(), // Asegurarse de que sea String, no String?
        password: password.trim(),
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Error en login Firebase: $e');
      
      // Si el usuario no existe, lo creamos automáticamente
      if (e.code == 'user-not-found') {
        return await createUserWithEmailAndPassword(email, password);
      }
      
      return null;
    } catch (e) {
      print('Error inesperado: $e');
      return null;
    }
  }
    
  // Crear usuario en Firebase Auth
  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Error creando usuario: $e');
      return null;
    }
  }
  
  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Verificar si hay un usuario autenticado
  Future<bool> isUserAuthenticated() async {
    return _auth.currentUser != null;
  }
}