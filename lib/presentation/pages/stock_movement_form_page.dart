import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockmaster/data/models/product_model.dart';
import 'package:stockmaster/data/models/user_model.dart';
import 'package:stockmaster/presentation/cubits/auth_cubit.dart';
import 'package:stockmaster/presentation/cubits/stock_movement_cubit.dart';

class StockMovementFormPage extends StatefulWidget {
  final ProductModel? product;

  const StockMovementFormPage({super.key, this.product});

  @override
  State<StockMovementFormPage> createState() => _StockMovementFormPageState();
}

class _StockMovementFormPageState extends State<StockMovementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _referenceController = TextEditingController();

  String _selectedType = 'entry';
  ProductModel? _selectedProduct;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.product;
    
    // Obtener usuario actual
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _currentUser = authState.user;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedProduct != null && _currentUser != null) {
      final quantity = int.tryParse(_quantityController.text) ?? 0;
      
      context.read<StockMovementCubit>().performStockMovement(
        productId: _selectedProduct!.id,
        type: _selectedType,
        quantity: quantity,
        reason: _reasonController.text,
        reference: _referenceController.text,
        user: _currentUser!,
      ).then((_) {
        // Navegar back después de un movimiento exitoso
        Navigator.of(context).pop(true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimiento de Stock'),
      ),
      body: BlocListener<StockMovementCubit, StockMovementState>(
        listener: (context, state) {
          if (state is StockMovementError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Producto seleccionado
                if (_selectedProduct != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.inventory_2),
                      title: Text(_selectedProduct!.name),
                      subtitle: Text('Código: ${_selectedProduct!.code} • Stock actual: ${_selectedProduct!.stock}'),
                    ),
                  ),
                
                const SizedBox(height: 16),

                // Tipo de movimiento
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  items: const [
                    DropdownMenuItem(value: 'entry', child: Text('Entrada de Stock')),
                    DropdownMenuItem(value: 'exit', child: Text('Salida de Stock')),
                    DropdownMenuItem(value: 'adjustment', child: Text('Ajuste de Stock')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Movimiento',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // Cantidad
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    border: OutlineInputBorder(),
                    hintText: 'Ingrese la cantidad',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese la cantidad';
                    }
                    final quantity = int.tryParse(value);
                    if (quantity == null || quantity <= 0) {
                      return 'La cantidad debe ser un número positivo';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Motivo
                TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: Compra, Venta, Ajuste físico...',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el motivo';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Referencia
                TextFormField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Referencia (Opcional)',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: Factura #123, Orden de compra...',
                  ),
                ),

                const SizedBox(height: 24),

                // Botón de enviar
                BlocBuilder<StockMovementCubit, StockMovementState>(
                  builder: (context, state) {
                    if (state is StockMovementLoading) {
                      return const ElevatedButton(
                        onPressed: null,
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    return ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.save),
                      label: const Text('Registrar Movimiento'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}