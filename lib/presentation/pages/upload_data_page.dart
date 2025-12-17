// upload_data_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockmaster/presentation/cubits/sync_cubit.dart';

class UploadDataPage extends StatelessWidget {
  const UploadDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir Datos a Firebase'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<SyncCubit, SyncState>(
        listener: (context, state) {
          if (state is SyncError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildConnectionStatus(context),
                const SizedBox(height: 20),
                _buildUploadCard(context, state),
                const SizedBox(height: 20),
                _buildStatsCard(context, state),
                const SizedBox(height: 20),
                _buildActionButtons(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado de Conexión',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.cloud, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Firebase Cloud Firestore'),
                      Text(
                        'Listo para sincronizar',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard(BuildContext context, SyncState state) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📤 Subir Datos Locales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sube todos los datos almacenados localmente a Firebase Cloud Firestore.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            if (state is SyncProgress)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: state.progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else if (state is SyncLoading)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Procesando...'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, SyncState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Estadísticas Locales',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.bar_chart),
              label: const Text('Ver Estadísticas'),
              onPressed: () {
                context.read<SyncCubit>().getUploadStats();
              },
            ),
            const SizedBox(height: 12),
            if (state is SyncSuccess && state.result['stats'] != null)
              _buildStatsTable(state.result['stats']),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTable(Map<String, dynamic> stats) {
    final categories = stats['categories'] as Map? ?? {};
    final products = stats['products'] as Map? ?? {};
    final suppliers = stats['suppliers'] as Map? ?? {};
    final users = stats['users'] as Map? ?? {};

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      children: [
        const TableRow(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text('No Sinc.', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        TableRow(
          children: [
            const Text('📁 Categorías'),
            Text('${categories['total'] ?? 0}'),
            Text('${categories['unsynced'] ?? 0}'),
          ],
        ),
        TableRow(
          children: [
            const Text('📦 Productos'),
            Text('${products['total'] ?? 0}'),
            Text('${products['unsynced'] ?? 0}'),
          ],
        ),
        TableRow(
          children: [
            const Text('🏢 Proveedores'),
            Text('${suppliers['total'] ?? 0}'),
            Text('${suppliers['unsynced'] ?? 0}'),
          ],
        ),
        TableRow(
          children: [
            const Text('👥 Usuarios'),
            Text('${users['total'] ?? 0}'),
            Text('${users['unsynced'] ?? 0}'),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, SyncState state) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.cloud_upload),
            label: const Text(
              'SUBIR TODOS LOS DATOS A FIREBASE',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: state is SyncLoading || state is SyncProgress
                ? null
                : () {
                    _showUploadConfirmationDialog(context);
                  },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.sync),
            label: const Text('Sincronización Bidireccional'),
            onPressed: state is SyncLoading || state is SyncProgress
                ? null
                : () {
                    context.read<SyncCubit>().syncBidirectional();
                  },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Probar Conexión'),
            onPressed: state is SyncLoading || state is SyncProgress
                ? null
                : () {
                    context.read<SyncCubit>().testSync();
                  },
          ),
        ),
      ],
    );
  }

  void _showUploadConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmar Subida'),
        content: const Text(
          '¿Estás seguro de que deseas subir TODOS los datos locales a Firebase?\n\n'
          'Esta acción sobrescribirá cualquier dato existente en la nube.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              context.read<SyncCubit>().uploadAllLocalData();
            },
            child: const Text('Subir Datos'),
          ),
        ],
      ),
    );
  }
}