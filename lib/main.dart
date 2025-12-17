// main.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:stockmaster/core/dependency_injection.dart';
import 'package:stockmaster/data/models/user_model.dart';
import 'app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:stockmaster/data/isar/isar_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== INICIANDO APLICACIÓN STOCKMASTER ===');
  
  try {
    print('1. Inicializando Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✓ Firebase inicializado');
    
    print('2. Configurando dependencias...');
    await setupDependencies();
    print('✓ Dependencias configuradas');
    
    print('3. Verificando configuración de usuarios...');
    
    // Obtener instancias necesarias
    final isarService = getIt<IsarService>();
    
    // Verificar si el usuario admin existe y tiene email
    final adminUser = await isarService.getUserByUsername('admin');
    
    if (adminUser != null) {
      print('   Usuario admin encontrado localmente');
      print('   Email actual: ${adminUser.email}');
      print('   FirebaseId actual: ${adminUser.firebaseId ?? "No asignado"}');
      
      // Si no tiene email, corregirlo
      if (adminUser.email.isEmpty) {
        print('   ⚠ Admin sin email, corrigiendo...');
        await isarService.isar.writeTxn(() async {
          adminUser.email = 'admin@stockmaster.com';
          await isarService.isar.userModels.put(adminUser);
        });
        print('   ✅ Email del admin corregido');
      }
    } else {
      print('   ℹ Usuario admin no encontrado, se creará al inicializar');
    }
    
    print('✓ Verificación completada');
    
    print('4. Ejecutando aplicación...');
    runApp(const MyApp());
    print('✓ Aplicación en ejecución');
    
  } catch (e, stackTrace) {
    print('✗ ERROR CRÍTICO DURANTE LA INICIALIZACIÓN: $e');
    print('Stack trace: $stackTrace');
    
    // App de error temporal
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Error Inicializando StockMaster',
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.bold,
                    color: Colors.red
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Detalles del error:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e.toString(),
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Posibles soluciones:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Verifica tu conexión a internet\n'
                  '2. Asegúrate de que Firebase esté configurado correctamente\n'
                  '3. Reinstala la aplicación\n'
                  '4. Contacta al soporte técnico',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  onPressed: () {
                    // Recargar la aplicación
                    runApp(const MyApp());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}