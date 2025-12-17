// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockmaster/core/dependency_injection.dart';
import 'package:stockmaster/presentation/cubits/sync_cubit.dart';

class SyncTestPage extends StatelessWidget {
  const SyncTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de Sincronización Firebase'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocProvider(
        create: (context) => getIt<SyncCubit>(),
        child: const _SyncTestContent(),
      ),
    );
  }
}

class _SyncTestContent extends StatelessWidget {
  const _SyncTestContent();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SyncCubit, SyncState>(
      listener: (context, state) {
        if (state is SyncError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Prueba de Conexión Firebase',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Esta herramienta verifica la conexión con Firebase Firestore y la sincronización de datos.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      _buildStatusIndicator(state),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.sync),
                      label: const Text('Prueba Completa'),
                      onPressed: state is! SyncLoading
                          ? () => context.read<SyncCubit>().testSync()
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Sincronización Rápida'),
                      onPressed: state is! SyncLoading
                          ? () => context.read<SyncCubit>().quickSync()
                          : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
              
              ElevatedButton.icon(
                icon: const Icon(Icons.cleaning_services),
                label: const Text('Limpiar Resultados'),
                onPressed: state is! SyncLoading
                    ? () => context.read<SyncCubit>().reset()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.grey[800],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Resultados
              Expanded(
                child: _buildResultsPanel(state),
              ),
            ],
          ),
        );
      },
    );
  }

  
  
  Widget _buildStatusIndicator(SyncState state) {
    Color color;
    String text;
    IconData icon;
    
    if (state is SyncLoading) {
      color = Colors.blue;
      text = 'Sincronizando...';
      icon = Icons.sync;
    } else if (state is SyncSuccess) {
      color = Colors.green;
      text = 'Sincronización exitosa';
      icon = Icons.check_circle;
    } else if (state is SyncError) {
      color = Colors.red;
      text = 'Error en sincronización';
      icon = Icons.error;
    } else {
      color = Colors.grey;
      text = 'Listo para probar';
      icon = Icons.pending;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultsPanel(SyncState state) {
    if (state is SyncInitial) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_queue, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Presiona "Prueba Completa" para comenzar',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    if (state is SyncLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Verificando conexión con Firebase...'),
          ],
        ),
      );
    }
    
    if (state is SyncError) {
      return _buildResultsList(state.message as Map<String, dynamic>?, isError: true);
    }
    
    if (state is SyncSuccess) {
      return _buildResultsList(state.result);
    }
    
    return const SizedBox();
  }
  
  Widget _buildResultsList(Map<String, dynamic>? result, {bool isError = false}) {
    if (result == null || result['steps'] == null) {
      return const Center(child: Text('No hay resultados disponibles'));
    }
    
    final steps = result['steps'] as List<dynamic>;
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              isError ? 'Resultados con errores' : 'Resultados detallados',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: steps.length,
              itemBuilder: (context, index) {
                final step = steps[index] as Map<String, dynamic>;
                final isStepError = step['isError'] == true;
                final isStepWarning = step['isWarning'] == true;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isStepError
                        ? Colors.red.shade50
                        : (isStepWarning
                            ? Colors.orange.shade50
                            : Colors.green.shade50),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isStepError
                          ? Colors.red.shade200
                          : (isStepWarning
                              ? Colors.orange.shade200
                              : Colors.green.shade200),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isStepError
                            ? Icons.error
                            : (isStepWarning
                                ? Icons.warning
                                : Icons.check_circle),
                        color: isStepError
                            ? Colors.red
                            : (isStepWarning
                                ? Colors.orange
                                : Colors.green),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step['message']?.toString() ?? '',
                              style: TextStyle(
                                color: isStepError
                                    ? Colors.red.shade800
                                    : Colors.black87,
                              ),
                            ),
                            if (step['timestamp'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _formatTime(step['timestamp']),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          if (result['error'] != null && (result['error'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detalles del error:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result['error'].toString(),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  String _formatTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }
}