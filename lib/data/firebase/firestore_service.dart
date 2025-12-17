// data/firebase/firestore_service.dart
// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Método estático para compatibilidad (opcional)
  static FirestoreService get instance => FirestoreService();
  
  // Colecciones
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get categories => _firestore.collection('categories');
  CollectionReference get products => _firestore.collection('products');
  CollectionReference get suppliers => _firestore.collection('suppliers');
  CollectionReference get stockMovements => _firestore.collection('stock_movements');
  
  // Obtener usuario actual de Firebase Auth
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
  
  // Crear/actualizar usuario en Firestore
  Future<void> createOrUpdateUser(Map<String, dynamic> userData) async {
    try {
      final userId = userData['firebaseId'] ?? userData['email'];
      if (userId == null) {
        print('❌ No se puede crear usuario sin firebaseId o email');
        return;
      }
      
      await users.doc(userId.toString()).set(
        userData,
        SetOptions(merge: true),
      );
      print('✅ Usuario creado/actualizado en Firestore: $userId');
    } catch (e) {
      print('❌ Error creando usuario en Firestore: $e');
    }
  }
  
  // Obtener usuario de Firestore por email
  Future<Object?> getUserByEmail(String email) async {
    try {
      final query = await users
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo usuario de Firestore: $e');
      return null;
    }
  }
  
  // Verificar si un usuario existe en Firestore
  Future<bool> userExistsInFirestore(String email) async {
    try {
      final query = await users
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error verificando usuario en Firestore: $e');
      return false;
    }
  }
  
  // Métodos para obtener colecciones filtradas por usuario actual
  Query<Map<String, dynamic>> getCategoriesQuery() {
    final uid = currentUserId;
    if (uid == null) return _firestore.collection('categories').where('userId', isEqualTo: '');
    
    return _firestore.collection('categories')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true);
  }
  
  Query<Map<String, dynamic>> getProductsQuery() {
    final uid = currentUserId;
    if (uid == null) return _firestore.collection('products').where('userId', isEqualTo: '');
    
    return _firestore.collection('products')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true);
  }
  
  Query<Map<String, dynamic>> getSuppliersQuery() {
    final uid = currentUserId;
    if (uid == null) return _firestore.collection('suppliers').where('userId', isEqualTo: '');
    
    return _firestore.collection('suppliers')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true);
  }
  
  // Verificar si un documento existe para el usuario actual
  Future<bool> documentExistsForCurrentUser(String collection, String field, String value) async {
    final uid = currentUserId;
    if (uid == null) return false;
    
    final query = await _firestore.collection(collection)
        .where('userId', isEqualTo: uid)
        .where(field, isEqualTo: value)
        .limit(1)
        .get();
    
    return query.docs.isNotEmpty;
  }
  
  // Método para probar conexión
  Future<bool> testConnection() async {
    try {
      await _firestore.collection('test').doc('test').set({'test': true});
      await _firestore.collection('test').doc('test').delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error de conexión a Firestore: $e');
      }
      return false;
    }
  }
  
  // Sincronizar todos los usuarios locales a Firestore
  Future<void> syncAllUsersToFirestore(List<Map<String, dynamic>> users) async {
    try {
      print('🔄 Sincronizando ${users.length} usuarios con Firestore...');
      
      for (final user in users) {
        await createOrUpdateUser(user);
      }
      
      print('✅ Todos los usuarios sincronizados a Firestore');
    } catch (e) {
      print('❌ Error sincronizando usuarios: $e');
    }
  }
}