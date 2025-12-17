// data/isar/isar_service.dart
import 'dart:async';
import 'dart:io'; 
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stockmaster/data/models/category_model.dart';
import 'package:stockmaster/data/models/product_model.dart';
import 'package:stockmaster/data/models/stock_movement_model.dart';
import 'package:stockmaster/data/models/supplier_model.dart';
import 'package:stockmaster/data/models/user_model.dart';

class IsarService {
  static final IsarService _instance = IsarService._internal();
  factory IsarService() => _instance;
  IsarService._internal();

  Isar? _isar;
  Completer<void>? _initializationCompleter;

  Future<void> initialize() async {
    // Si ya hay un proceso de inicialización en curso, esperarlo
    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    _initializationCompleter = Completer<void>();
    
    try {
      // OBTENER DIRECTORIO CORRECTO PARA CADA PLATAFORMA
      String databaseDirectory;
      
      if (Platform.isAndroid || Platform.isIOS) {
        // Para móviles: usar el directorio de documentos de la app
        final dir = await getApplicationDocumentsDirectory();
        databaseDirectory = dir.path;
      } 
      else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Para escritorio: crear un directorio específico en Documentos
        final documentsDir = await getApplicationDocumentsDirectory();
        databaseDirectory = '${documentsDir.path}/StockMasterDB';
        
        // Crear el directorio si no existe
        final dir = Directory(databaseDirectory);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        
        if (kDebugMode) {
          print('🖥️ Ruta de base de datos en Windows: $databaseDirectory');
        }
      } 
      else {
        // Para otras plataformas, fallback al directorio actual
        databaseDirectory = '.';
      }

      // ABRIR LA BASE DE DATOS
      _isar = await Isar.open(
        [
          ProductModelSchema,
          CategoryModelSchema,
          SupplierModelSchema,
          StockMovementModelSchema,
          UserModelSchema
        ],
        directory: databaseDirectory,
        name: 'stockmaster_db', // Nombre explícito del archivo .isar
      );
      
      if (kDebugMode) {
        print('✅ Isar inicializado en: $databaseDirectory/stockmaster_db.isar');
      }
      
      _initializationCompleter!.complete();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error inicializando Isar: $e');
      }
      _initializationCompleter!.completeError(e);
      rethrow;
    }
  }

  // ... resto de tus métodos permanecen igual ...
  Future<UserModel?> getUserByUsername(String username) async {
    try {
      return await isar.userModels
          .where()
          .filter()
          .usernameEqualTo(username)
          .findFirst();
    } catch (e) {
      if (kDebugMode) {
        print('Error en getUserByUsername: $e');
      }
      return null;
    }
  }

  Future<UserModel?> getUserByEmail(String email) async {
    try {
      // Buscar todos los usuarios y filtrar por email
      final allUsers = await isar.userModels.where().findAll();
      for (final user in allUsers) {
        if (user.email == email) {
          return user;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error en getUserByEmail: $e');
      }
      return null;
    }
  }

  Isar get isar {
    if (_isar == null) {
      throw Exception('Isar no está inicializado. Llama a initialize() primero.');
    }
    return _isar!;
  }

  Future<Isar> get isarAsync async {
    if (_isar == null) {
      await initialize();
    }
    return _isar!;
  }
}