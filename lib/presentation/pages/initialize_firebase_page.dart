// presentation/pages/initialize_firebase_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:stockmaster/core/dependency_injection.dart';
import 'package:stockmaster/data/firebase/firebase_initializer.dart';
import 'package:stockmaster/data/firebase/firestore_service.dart';
import 'package:stockmaster/data/isar/isar_service.dart';

class InitializeFirebasePage extends StatefulWidget {
  const InitializeFirebasePage({super.key});

  @override
  State<InitializeFirebasePage> createState() => _InitializeFirebasePageState();
}

class _InitializeFirebasePageState extends State<InitializeFirebasePage> {
  bool _isLoading = false;
  String _status = '';

  Future<void> _initializeFirestore() async {
    setState(() {
      _isLoading = true;
      _status = 'Inicializando Firestore...';
    });

    try {
      final initializer = FirebaseInitializer(
        getIt<FirestoreService>(),
        getIt<IsarService>(),
      );
      
      await initializer.initializeFirestoreUsers();
      
      setState(() {
        _status = '✅ Firestore inicializado correctamente';
      });
      
      await Future.delayed(const Duration(seconds: 2));
      Navigator.of(context).pop();
      
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicializar Firebase')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_upload, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'Configuración de Firebase',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Es necesario crear los usuarios en Firestore para la sincronización.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              if (_status.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(_status, textAlign: TextAlign.center),
                ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _initializeFirestore,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Inicializar Firestore'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}