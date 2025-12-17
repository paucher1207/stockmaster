// presentation/pages/supplier_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/supplier_cubit.dart';
import '../../data/models/supplier_model.dart';

class SupplierFormPage extends StatefulWidget {
  final SupplierModel? supplier;

  const SupplierFormPage({super.key, this.supplier});

  @override
  State<SupplierFormPage> createState() => _SupplierFormPageState();
}

class _SupplierFormPageState extends State<SupplierFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Si estamos editando, cargamos los datos del proveedor
    if (widget.supplier != null) {
      _nameController.text = widget.supplier!.name;
      _contactController.text = widget.supplier!.contact;
      _phoneController.text = widget.supplier!.phone;
      _emailController.text = widget.supplier!.email;
      _addressController.text = widget.supplier!.address ?? '';
      _notesController.text = widget.supplier!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final supplier = SupplierModel()
        ..name = _nameController.text.trim()
        ..contact = _contactController.text.trim()
        ..phone = _phoneController.text.trim()
        ..email = _emailController.text.trim()
        ..address = _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null
        ..notes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null
        ..createdAt = DateTime.now();

      // Si estamos editando, mantener el ID
      if (widget.supplier != null) {
        supplier.id = widget.supplier!.id;
      }

      // Guardar el proveedor
      if (widget.supplier == null) {
        await context.read<SupplierCubit>().addSupplier(supplier);
      } else {
        await context.read<SupplierCubit>().updateSupplier(supplier);
      }
      
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
        title: Text(widget.supplier == null ? 'Agregar Proveedor' : 'Editar Proveedor'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveSupplier,
            ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildNameField(),
                    const SizedBox(height: 16),
                    _buildContactField(),
                    const SizedBox(height: 16),
                    _buildPhoneField(),
                    const SizedBox(height: 16),
                    _buildEmailField(),
                    const SizedBox(height: 16),
                    _buildAddressField(),
                    const SizedBox(height: 16),
                    _buildNotesField(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Nombre de la empresa',
        hintText: 'Ej: TecnoSuministros S.A.',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.business),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa el nombre de la empresa';
        }
        return null;
      },
    );
  }

  Widget _buildContactField() {
    return TextFormField(
      controller: _contactController,
      decoration: const InputDecoration(
        labelText: 'Persona de contacto',
        hintText: 'Ej: Juan Pérez',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa el contacto';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      decoration: const InputDecoration(
        labelText: 'Teléfono',
        hintText: 'Ej: +34 600 123 456',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.phone),
      ),
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa el teléfono';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'Ej: contacto@empresa.com',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.email),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa el email';
        }
        if (!value.contains('@')) {
          return 'Por favor ingresa un email válido';
        }
        return null;
      },
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      decoration: const InputDecoration(
        labelText: 'Dirección (opcional)',
        hintText: 'Ej: Calle Principal 123, Ciudad',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_on),
      ),
      maxLines: 2,
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notas (opcional)',
        hintText: 'Información adicional sobre el proveedor',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.note),
      ),
      maxLines: 3,
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveSupplier,
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
              widget.supplier == null ? 'Guardar Proveedor' : 'Actualizar Proveedor',
              style: const TextStyle(fontSize: 16),
            ),
    );
  }
}