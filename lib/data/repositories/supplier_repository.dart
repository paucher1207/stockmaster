// ignore_for_file: avoid_print

import 'package:isar/isar.dart';
import 'package:stockmaster/data/isar/isar_service.dart';
import 'package:stockmaster/data/models/supplier_model.dart';

class SupplierRepository {
  final IsarService _isarService;

  SupplierRepository(this._isarService);

  // Obtener todos los proveedores activos
  Future<List<SupplierModel>> getAllSuppliers() async {
    final isar = _isarService.isar;
    return await isar.supplierModels.where().findAll();
  }

  // Obtener proveedor por ID
  Future<SupplierModel?> getSupplierById(int id) async {
    final isar = _isarService.isar;
    return await isar.supplierModels.get(id);
  }

  // Crear proveedor
  Future<int> createSupplier(SupplierModel supplier) async {
    final isar = _isarService.isar;
    supplier.createdAt = DateTime.now();
    
    return await isar.writeTxn(() async {
      return await isar.supplierModels.put(supplier);
    });
  }

  // Actualizar proveedor
  Future<bool> updateSupplier(SupplierModel supplier) async {
    final isar = _isarService.isar;
    
    final success = await isar.writeTxn(() async {
      return await isar.supplierModels.put(supplier) > 0;
    });
    
    return success;
  }

  // Eliminar proveedor
  Future<bool> deleteSupplier(int id) async {
    final isar = _isarService.isar;
    return await isar.writeTxn(() async {
      return await isar.supplierModels.delete(id);
    });
  }

  // Buscar proveedores
  Future<List<SupplierModel>> searchSuppliers(String query) async {
    final isar = _isarService.isar;
    
    if (query.isEmpty) {
      return await getAllSuppliers();
    }
    
    final lowerQuery = query.toLowerCase();
    
    return await isar.supplierModels
        .where()
        .filter()
        .nameContains(lowerQuery, caseSensitive: false)
        .or()
        .contactContains(lowerQuery, caseSensitive: false)
        .or()
        .emailContains(lowerQuery, caseSensitive: false)
        .findAll();
  }

  // Inicializar datos de ejemplo - CORREGIDO
 Future<void> initializeSampleData() async {
    try {
      final isar = _isarService.isar;

      // 1. DEFINIR DATOS DE EJEMPLO CON CÓDIGOS FIJOS
      const sampleSuppliersData = [
        {
          'code': 'PROV-EXAMPLE-001',
          'name': 'TecnoSuministros S.A.',
          'contact': 'Juan Pérez',
          'phone': '+34 600 123 456',
          'email': 'juan@tecnosuministros.com',
          'address': 'Calle Tecnología 123, Madrid',
          'notes': 'Proveedor oficial de componentes electrónicos',
        },
        {
          'code': 'PROV-EXAMPLE-002',
          'name': 'Muebles Office SL',
          'contact': 'María García',
          'phone': '+34 600 654 321',
          'email': 'maria@mueblesoffice.com',
          'address': 'Avenida Oficinas 45, Barcelona',
          'notes': 'Mobiliario de oficina y ergonómico',
        },
        {
          'code': 'PROV-EXAMPLE-003',
          'name': 'Accesorios Digitales',
          'contact': 'Carlos López',
          'phone': '+34 600 789 012',
          'email': 'carlos@accesoriosdigitales.com',
          'address': 'Plaza Digital 67, Valencia',
          'notes': 'Accesorios y periféricos de computación',
        },
      ];

      print('Verificando proveedores de ejemplo...');
      int createdCount = 0;
      int skippedCount = 0;

      // 2. VERIFICAR E INSERTAR UNO POR UNO (TRANSACCIÓN EXTERNA)
      for (final data in sampleSuppliersData) {
        // Verificar por CÓDIGO (campo único)
        final existingByCode = await _getSupplierByCode(data['code']!);
        
        // También verificar por nombre por si acaso
        final existingByName = await _getSupplierByName(data['name']!);

        if (existingByCode != null || existingByName != null) {
          print('  - Proveedor ya existe: ${data['name']} (código: ${data['code']})');
          skippedCount++;
          continue; // Saltar a la siguiente iteración
        }

        // Crear nuevo proveedor
        final supplier = SupplierModel()
          ..code = data['code']! // Se sobrescribe el código generado automáticamente
          ..name = data['name']!
          ..contact = data['contact']!
          ..phone = data['phone']!
          ..email = data['email']!
          ..address = data['address']!
          ..notes = data['notes']!
          ..createdAt = DateTime.now()
          ..isActive = true;

        // Insertar en transacción individual para mejor control de errores
        await isar.writeTxn(() async {
          await isar.supplierModels.put(supplier);
        });
        
        print('  + Proveedor creado: ${supplier.name} (${supplier.code})');
        createdCount++;
      }

      if (createdCount > 0) {
        print('✓ Proveedores de ejemplo creados: $createdCount');
      }
      if (skippedCount > 0) {
        print('✓ Proveedores omitidos (ya existían): $skippedCount');
      }
      if (createdCount == 0 && skippedCount == 0) {
        print('ℹ No se procesaron proveedores de ejemplo');
      }
      
    } catch (e) {
      print('⚠ Error al cargar proveedores de ejemplo: $e');
      // Para debugging detallado
      print('  Tipo de error: ${e.runtimeType}');
      if (e is IsarError) {
        print('  IsarError detalles: ${e.message}');
      }
    }
  }

  // Método auxiliar para buscar proveedor por nombre
  Future<SupplierModel?> _getSupplierByName(String name) async {
    final isar = _isarService.isar;
    return await isar.supplierModels
        .where()
        .filter()
        .nameEqualTo(name)
        .findFirst();
  }

  // NUEVO MÉTODO: Buscar proveedor por código
  Future<SupplierModel?> _getSupplierByCode(String code) async {
    final isar = _isarService.isar;
    return await isar.supplierModels
        .where()
        .filter()
        .codeEqualTo(code)
        .findFirst();
  }
}