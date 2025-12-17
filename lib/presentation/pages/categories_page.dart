// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockmaster/data/models/user_model.dart';
import 'package:stockmaster/presentation/cubits/auth_cubit.dart';
import '../cubits/category_cubit.dart';
import '../../data/models/category_model.dart';
import 'category_form_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  void _loadCategories() {
    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;
    
    if (authState is AuthAuthenticated) {
      final allowedCategoryIds = authCubit.getAllowedCategoryIds();
      final categoryCubit = context.read<CategoryCubit>();
      
      // Configurar categorías permitidas
      categoryCubit.setAllowedCategoryIds(allowedCategoryIds);
      categoryCubit.loadCategories();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            if (authState is AuthAuthenticated) {
              return Row(
                children: [
                  const Text('Categorías'),
                  const SizedBox(width: 10),
                  if (authState.user.assignedCategoryId != null)
                    Chip(
                      label: Text('Categoría ${authState.user.assignedCategoryId}'),
                      backgroundColor: Colors.white.withOpacity(0.3),
                    ),
                ],
              );
            }
            return const Text('Categorías');
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Solo mostrar botón de agregar si es admin
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              final canEdit = authState is AuthAuthenticated && 
                            (authState.user.role == UserRole.admin);
              
              if (canEdit) {
                return IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _navigateToCategoryForm(context);
                  },
                );
              }
              return const SizedBox();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context);
            },
          ),
        ],
      ),
      body: BlocBuilder<CategoryCubit, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CategoryError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is CategoryLoaded) {
            return _buildCategoriesList(context, state.categories);
          } else {
            return const Center(
              child: Text('Presiona el botón + para agregar una categoría'),
            );
          }
        },
      ),
      floatingActionButton: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final canEdit = authState is AuthAuthenticated && 
                        (authState.user.role == UserRole.admin);
          
          if (canEdit) {
            return FloatingActionButton(
              onPressed: () {
                _navigateToCategoryForm(context);
              },
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildCategoriesList(BuildContext context, List<CategoryModel> categories) {
    if (categories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay categorías registradas'),
            Text('Presiona el botón + para agregar una'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.category),
            title: Text(category.name),
            subtitle: Text(category.description),
            trailing: Text('ID: ${category.id}'),
            onTap: () {
              _navigateToEditCategory(context, category);
            },
            onLongPress: () {
              _showCategoryOptions(context, category);
            },
          ),
        );
      },
    );
  }

  void _navigateToCategoryForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<CategoryCubit>(),
          child: const CategoryFormPage(),
        ),
      ),
    );
  }

  void _navigateToEditCategory(BuildContext context, CategoryModel category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<CategoryCubit>(),
          child: CategoryFormPage(category: category),
        ),
      ),
    );
  }

  void _showCategoryOptions(BuildContext context, CategoryModel category) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar Categoría'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditCategory(context, category);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Eliminar Categoría',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, category);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Categoría'),
          content: Text(
              '¿Estás seguro de que quieres eliminar "${category.name}"? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<CategoryCubit>().deleteCategory(category.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${category.name}" eliminada'),
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

  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Buscar Categorías'),
          content: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Ingresa el nombre de la categoría...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              context.read<CategoryCubit>().searchCategories(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.read<CategoryCubit>().loadCategories();
                Navigator.pop(context);
              },
              child: const Text('Limpiar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    ).then((_) {
      // ignore: use_build_context_synchronously
      context.read<CategoryCubit>().loadCategories();
    });
  }
}