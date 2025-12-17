// presentation/pages/product_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockmaster/data/models/category_model.dart';
import '../cubits/product_cubit.dart';
import '../cubits/category_cubit.dart';
import '../cubits/auth_cubit.dart';
import '../../data/models/product_model.dart';
import '../../data/models/user_model.dart';

class ProductFormPage extends StatefulWidget {
  final ProductModel? product;

  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();

  int? _selectedCategoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Si estamos editando, cargamos los datos del producto
    if (widget.product != null) {
      _codeController.text = widget.product!.code;
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _priceController.text = widget.product!.price.toString();
      _costController.text = widget.product!.cost.toString();
      _stockController.text = widget.product!.stock.toString();
      _minStockController.text = widget.product!.minStock.toString();
      _selectedCategoryId = widget.product!.categoryId;
    }

    // Cargar categorías cuando se inicia la página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryCubit>().loadCategories();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct(UserModel user) async {
    if (!_formKey.currentState!.validate()) return;

    // Verificar permisos para manager
    if (user.isManager && !user.hasAccessToCategory(_selectedCategoryId ?? -1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para crear/editar productos en esta categoría'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final product = ProductModel()
        ..code = _codeController.text.trim()
        ..name = _nameController.text.trim()
        ..description = _descriptionController.text.trim()
        ..price = double.parse(_priceController.text)
        ..cost = double.parse(_costController.text)
        ..stock = int.parse(_stockController.text)
        ..minStock = int.parse(_minStockController.text)
        ..createdAt = DateTime.now();

      // Asignar categoría
      product.categoryId = _selectedCategoryId;

      // Si el usuario es manager, forzar la categoría asignada
      if (user.isManager && _selectedCategoryId == null) {
        product.categoryId = user.assignedCategoryId;
      }

      // Si estamos editando, mantener el ID
      if (widget.product != null) {
        product.id = widget.product!.id;
      }

      // Guardar el producto
      await context.read<ProductCubit>().addProduct(product);
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Agregar Producto' : 'Editar Producto'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                final authCubit = context.read<AuthCubit>();
                final authState = authCubit.state;
                if (authState is AuthAuthenticated) {
                  await _saveProduct(authState.user);
                }
              },
            ),
        ],
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = authState.user;

          // Verificar permisos para acceder al formulario
          if (!user.canEditProducts) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Acceso Denegado',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No tienes permisos para crear o editar productos.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Volver'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Si es manager y está editando un producto, verificar que tenga acceso a la categoría
          if (widget.product != null && 
              user.isManager && 
              !user.hasAccessToCategory(widget.product!.categoryId ?? -1)) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Acceso Denegado',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No tienes permisos para editar este producto.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Volver'),
                    ),
                  ],
                ),
              ),
            );
          }

          return _isSaving
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        _buildCodeField(),
                        const SizedBox(height: 16),
                        _buildNameField(),
                        const SizedBox(height: 16),
                        _buildDescriptionField(),
                        const SizedBox(height: 16),
                        _buildCategoryDropdown(context, user),
                        const SizedBox(height: 16),
                        _buildPriceField(),
                        const SizedBox(height: 16),
                        _buildCostField(),
                        const SizedBox(height: 16),
                        _buildStockField(),
                        const SizedBox(height: 16),
                        _buildMinStockField(),
                        const SizedBox(height: 24),
                        _buildSaveButton(user),
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context, UserModel user) {
    // Si el usuario es manager, mostrar categoría fija
    if (user.isManager) {
      return BlocBuilder<CategoryCubit, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoaded) {
            final category = state.categories.firstWhere(
              (cat) => cat.id == user.assignedCategoryId,
              orElse: () => CategoryModel()..name = 'Categoría no encontrada',
            );

            return TextFormField(
              initialValue: category.name,
              decoration: InputDecoration(
                labelText: 'Categoría',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.category),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              readOnly: true,
              enabled: false,
            );
          } else if (state is CategoryError) {
            return Text('Error: ${state.message}');
          } else {
            return const CircularProgressIndicator();
          }
        },
      );
    }

    // Si es admin, mostrar dropdown normal
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoaded) {
          final categories = state.categories;
          
          // Encontrar la categoría seleccionada para el dropdown
          String? selectedValue = _selectedCategoryId?.toString();
          
          return DropdownButtonFormField<String>(
            initialValue: selectedValue,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Sin categoría'),
              ),
              ...categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category.id.toString(),
                  child: Text(category.name),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategoryId = value == null ? null : int.parse(value);
              });
            },
          );
        } else if (state is CategoryError) {
          return Text('Error: ${state.message}');
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  Widget _buildCodeField() {
    return TextFormField(
      controller: _codeController,
      decoration: const InputDecoration(
        labelText: 'Código',
        hintText: 'Código único del producto',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.code),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa el código';
        }
        return null;
      },
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Nombre',
        hintText: 'Nombre del producto',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.inventory_2),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa el nombre';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Descripción',
        hintText: 'Descripción del producto',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 3,
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      decoration: const InputDecoration(
        labelText: 'Precio de venta',
        hintText: '0.00',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.attach_money),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa el precio';
        }
        if (double.tryParse(value) == null) {
          return 'Por favor ingresa un número válido';
        }
        return null;
      },
    );
  }

  Widget _buildCostField() {
    return TextFormField(
      controller: _costController,
      decoration: const InputDecoration(
        labelText: 'Costo',
        hintText: '0.00',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.money_off),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa el costo';
        }
        if (double.tryParse(value) == null) {
          return 'Por favor ingresa un número válido';
        }
        return null;
      },
    );
  }

  Widget _buildStockField() {
    return TextFormField(
      controller: _stockController,
      decoration: const InputDecoration(
        labelText: 'Stock actual',
        hintText: '0',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.inventory),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa el stock';
        }
        if (int.tryParse(value) == null) {
          return 'Por favor ingresa un número entero válido';
        }
        return null;
      },
    );
  }

  Widget _buildMinStockField() {
    return TextFormField(
      controller: _minStockController,
      decoration: const InputDecoration(
        labelText: 'Stock mínimo',
        hintText: '0',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.warning),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa el stock mínimo';
        }
        if (int.tryParse(value) == null) {
          return 'Por favor ingresa un número entero válido';
        }
        return null;
      },
    );
  }

  Widget _buildSaveButton(UserModel user) {
    return ElevatedButton(
      onPressed: _isSaving ? null : () => _saveProduct(user),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              widget.product == null ? 'Guardar Producto' : 'Actualizar Producto',
              style: const TextStyle(fontSize: 16),
            ),
    );
  }
}