// presentation/pages/suppliers_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/supplier_cubit.dart';
import '../../data/models/supplier_model.dart';
import 'supplier_form_page.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  @override
  void initState() {
    super.initState();
    // Cargar proveedores al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierCubit>().loadSuppliers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _navigateToSupplierForm(context);
            },
            tooltip: 'Agregar Proveedor',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SupplierCubit>().loadSuppliers();
            },
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: BlocBuilder<SupplierCubit, SupplierState>(
        builder: (context, state) {
          if (state is SupplierLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SupplierError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SupplierCubit>().loadSuppliers();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          } else if (state is SupplierLoaded) {
            return _buildSuppliersList(context, state.suppliers);
          } else {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 64, color: Colors.blue),
                  SizedBox(height: 16),
                  Text(
                    'Gestión de Proveedores',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Presiona el botón + para agregar proveedores'),
                ],
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateToSupplierForm(context);
        },
        tooltip: 'Agregar Proveedor',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSuppliersList(BuildContext context, List<SupplierModel> suppliers) {
    if (suppliers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay proveedores registrados',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Presiona el botón + para agregar uno',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header con contador
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Proveedores (${suppliers.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Botón para cargar datos de ejemplo
              TextButton.icon(
                onPressed: () {
                  context.read<SupplierCubit>().loadSampleData();
                },
                icon: const Icon(Icons.data_usage, size: 16),
                label: const Text('Datos de Ejemplo'),
              ),
            ],
          ),
        ),
        // Lista de proveedores
        Expanded(
          child: ListView.builder(
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final supplier = suppliers[index];
              return _buildSupplierItem(context, supplier);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierItem(BuildContext context, SupplierModel supplier) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.business,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          supplier.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contacto: ${supplier.contact}'),
            const SizedBox(height: 2),
            Text('Tel: ${supplier.phone}'),
            const SizedBox(height: 2),
            Text('Email: ${supplier.email}'),
            if (supplier.notes != null && supplier.notes!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                supplier.notes!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          _navigateToEditSupplier(context, supplier);
        },
        onLongPress: () {
          _showSupplierOptions(context, supplier);
        },
      ),
    );
  }

  void _showSupplierOptions(BuildContext context, SupplierModel supplier) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar Proveedor'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditSupplier(context, supplier);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Eliminar Proveedor',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, supplier);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, SupplierModel supplier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Proveedor'),
          content: Text(
              '¿Estás seguro de que quieres eliminar "${supplier.name}"? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<SupplierCubit>().deleteSupplier(supplier.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${supplier.name}" eliminado'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToSupplierForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<SupplierCubit>(),
          child: const SupplierFormPage(),
        ),
      ),
    );
  }

  void _navigateToEditSupplier(BuildContext context, SupplierModel supplier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<SupplierCubit>(),
          child: SupplierFormPage(supplier: supplier),
        ),
      ),
    );
  }
}