// presentation/pages/home_page.dart - VERSIÓN COMPLETA CORREGIDA
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockmaster/core/dependency_injection.dart';
import 'package:stockmaster/data/firebase/sync_service.dart';
import '../cubits/product_cubit.dart';
import '../cubits/auth_cubit.dart';
import '../../data/models/product_model.dart';
import '../../data/models/user_model.dart';
import 'product_form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isSyncing = false;
  String _syncMessage = '';
  int _syncProgress = 0;
  bool _isSyncDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  void _loadProducts() {
    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;
    
    if (authState is AuthAuthenticated) {
      final allowedCategoryIds = authCubit.getAllowedCategoryIds();
      final productCubit = context.read<ProductCubit>();
      
      productCubit.setAllowedCategoryIds(allowedCategoryIds);
      productCubit.loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authState.user;

        return Scaffold(
          appBar: AppBar(
            title: const Text('StockMaster'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.sync),
                onPressed: () => _showSyncDialog(context),
                tooltip: 'Sincronizar con Firebase',
              ),
              
              if (user.canViewDashboard)
                IconButton(
                  icon: const Icon(Icons.dashboard),
                  onPressed: () {
                    Navigator.pushNamed(context, '/dashboard');
                  },
                  tooltip: 'Ver Dashboard',
                ),
              if (user.canManageCategories)
                IconButton(
                  icon: const Icon(Icons.category),
                  onPressed: () {
                    Navigator.pushNamed(context, '/categories');
                  },
                  tooltip: 'Gestionar Categorías',
                ),
              if (user.canManageSuppliers)
                IconButton(
                  icon: const Icon(Icons.business),
                  onPressed: () {
                    Navigator.pushNamed(context, '/suppliers');
                  },
                  tooltip: 'Gestionar Proveedores',
                ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  _showSearchDialog(context);
                },
                tooltip: 'Buscar Productos',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.person),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.fullName),
                            Text(
                              user.roleDisplayName,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Cerrar Sesión'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'logout') {
                    context.read<AuthCubit>().logout();
                  }
                },
              ),
            ],
          ),
          body: BlocBuilder<ProductCubit, ProductState>(
            builder: (context, state) {
              if (state is ProductLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ProductError) {
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
                          _loadProducts();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              } else if (state is ProductLoaded) {
                return _buildProductList(context, state.products, user);
              } else {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 64, color: Colors.blue),
                      SizedBox(height: 16),
                      Text(
                        'Bienvenido a StockMaster',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Presiona el botón + para agregar productos'),
                    ],
                  ),
                );
              }
            },
          ),
          floatingActionButton: user.canEditProducts
              ? FloatingActionButton(
                  onPressed: () {
                    _navigateToProductForm(context);
                  },
                  tooltip: 'Agregar Producto',
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  void _navigateToProductForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProductFormPage(),
      ),
    );
  }

  void _navigateToEditProduct(BuildContext context, ProductModel product, UserModel user) {
    if (!user.canEditProducts || !user.hasAccessToCategory(product.categoryId ?? -1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para editar este producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormPage(product: product),
      ),
    );
  }

  Widget _buildProductList(BuildContext context, List<ProductModel> products, UserModel user) {
    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay productos registrados',
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
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenido, ${user.fullName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.roleDisplayName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  _buildSyncStatusIndicator(context),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Productos (${products.length})',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductItem(context, product, user);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductItem(BuildContext context, ProductModel product, UserModel user) {
    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle;
    String statusText = 'En Stock';

    if (product.stock == 0) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'Sin Stock';
    } else if (product.stock <= product.minStock) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'Stock Bajo';
    }

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
            Icons.inventory_2,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.code),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 14),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (product.categoryId != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.category, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Categoría ${product.categoryId}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'Stock: ${product.stock}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        onTap: () {
          _navigateToEditProduct(context, product, user);
        },
        onLongPress: user.canEditProducts ? () {
          _showProductOptions(context, product, user);
        } : null,
      ),
    );
  }

  Widget _buildSyncStatusIndicator(BuildContext context) {
    return FutureBuilder<bool>(
      future: getIt<SyncService>().checkConnection(),
      builder: (context, snapshot) {
        final hasConnection = snapshot.data ?? false;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: hasConnection 
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasConnection ? Colors.green : Colors.orange,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasConnection ? Icons.cloud_done : Icons.cloud_off,
                size: 16,
                color: hasConnection ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                hasConnection ? 'En línea' : 'Sin conexión',
                style: TextStyle(
                  fontSize: 12,
                  color: hasConnection ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProductOptions(BuildContext context, ProductModel product, UserModel user) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar Producto'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditProduct(context, product, user);
                },
              ),
              if (user.isAdmin)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Eliminar Producto',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, product);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Producto'),
          content: Text(
              '¿Estás seguro de que quieres eliminar "${product.name}"? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<ProductCubit>().deleteProduct(product.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${product.name}" eliminado'),
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
          title: const Text('Buscar Productos'),
          content: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Ingresa el nombre del producto...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              context.read<ProductCubit>().searchProducts(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.read<ProductCubit>().loadProducts();
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
      context.read<ProductCubit>().loadProducts();
    });
  }

  void _showSyncDialog(BuildContext context) async {
    if (_isSyncDialogOpen) return;
    
    final syncService = getIt<SyncService>();
    final authState = context.read<AuthCubit>().state;
    
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes estar autenticado para sincronizar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _isSyncDialogOpen = true;
    
    showDialog(
      context: context,
      barrierDismissible: !_isSyncing,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.sync, color: Colors.blue),
                  SizedBox(width: 10),
                  Text('Sincronización Firebase'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isSyncing) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            value: _syncProgress == 100 ? null : _syncProgress / 100,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _syncMessage,
                            textAlign: TextAlign.center,
                          ),
                          if (_syncProgress > 0 && _syncProgress < 100)
                            Text(
                              '${_syncProgress.toInt()}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Text('Selecciona el tipo de sincronización:'),
                    const SizedBox(height: 16),
                    _buildSyncOption(
                      context,
                      icon: Icons.cloud_upload,
                      title: 'Subir datos locales',
                      subtitle: 'Envía los datos no sincronizados a Firebase',
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _performSync(context, 'upload', syncService);
                      },
                    ),
                    _buildSyncOption(
                      context,
                      icon: Icons.cloud_download,
                      title: 'Descargar desde Firebase',
                      subtitle: 'Trae los datos remotos a tu dispositivo',
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _performSync(context, 'download', syncService);
                      },
                    ),
                    _buildSyncOption(
                      context,
                      icon: Icons.sync_alt,
                      title: 'Sincronización bidireccional',
                      subtitle: 'Sincroniza en ambas direcciones',
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _performSync(context, 'bidirectional', syncService);
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                if (_isSyncing)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _syncMessage = 'Cancelando...';
                      });
                      // No podemos cancelar fácilmente, pero al menos cerramos el diálogo
                      Navigator.of(context).pop();
                      _isSyncDialogOpen = false;
                      _isSyncing = false;
                    },
                    child: const Text('Cancelar'),
                  )
                else
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _isSyncDialogOpen = false;
                    },
                    child: const Text('Cancelar'),
                  ),
              ],
            );
          },
        );
      },
    ).then((_) {
      _isSyncDialogOpen = false;
    });
  }

  Widget _buildSyncOption(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performSync(BuildContext context, String type, SyncService syncService) async {
    if (_isSyncing) return;
    
    setState(() {
      _isSyncing = true;
      _syncProgress = 0;
      _syncMessage = 'Iniciando sincronización...';
    });

    final scaffold = ScaffoldMessenger.of(context);
    
    try {
      String message = '';
      
      // Actualizar progreso
      setState(() {
        _syncMessage = 'Verificando conexión...';
        _syncProgress = 10;
      });

      // Verificar conexión
      final hasConnection = await syncService.checkConnection();
      if (!hasConnection) {
        throw Exception('Sin conexión a internet');
      }

      // Actualizar progreso
      setState(() {
        _syncMessage = 'Obteniendo usuario actual...';
        _syncProgress = 20;
      });

      final currentUser = await syncService.getCurrentFirebaseUser();
      if (currentUser == null) {
        throw Exception('Usuario no autenticado en Firebase');
      }

      switch (type) {
        case 'upload':
          setState(() {
            _syncMessage = 'Subiendo categorías...';
            _syncProgress = 30;
          });
          await syncService.syncCategories(currentUser.uid);
          
          setState(() {
            _syncMessage = 'Subiendo proveedores...';
            _syncProgress = 50;
          });
          await syncService.syncSuppliers(currentUser.uid);
          
          setState(() {
            _syncMessage = 'Subiendo productos...';
            _syncProgress = 70;
          });
          await syncService.syncProducts(currentUser.uid);
          
          setState(() {
            _syncMessage = 'Completando subida...';
            _syncProgress = 90;
          });
          
          message = 'Datos locales subidos correctamente';
          break;
          
        case 'download':
          setState(() {
            _syncMessage = 'Descargando usuarios...';
            _syncProgress = 30;
          });
          await syncService.syncUserDataFromFirebase(currentUser.uid);
          
          setState(() {
            _syncMessage = 'Descargando categorías...';
            _syncProgress = 50;
          });
          await syncService.downloadCategories(currentUser.uid);
          
          setState(() {
            _syncMessage = 'Descargando proveedores...';
            _syncProgress = 70;
          });
          await syncService.downloadSuppliers(currentUser.uid);
          
          setState(() {
            _syncMessage = 'Descargando productos...';
            _syncProgress = 90;
          });
          await syncService.downloadProducts(currentUser.uid);
          
          message = 'Datos descargados desde Firebase';
          break;
          
        case 'bidirectional':
          setState(() {
            _syncMessage = 'Iniciando sincronización bidireccional...';
            _syncProgress = 20;
          });
          
          await syncService.syncBidirectional();
          
          message = 'Sincronización bidireccional completada';
          break;
      }

      setState(() {
        _syncMessage = 'Completando sincronización...';
        _syncProgress = 100;
      });

      // Esperar un momento para mostrar el progreso 100%
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        
        scaffold.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Refrescar la lista de productos
        context.read<ProductCubit>().loadProducts();
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        
        scaffold.showSnackBar(
          SnackBar(
            content: Text('Error en sincronización: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted && _isSyncDialogOpen) {
        Navigator.of(context).pop();
        _isSyncDialogOpen = false;
      }
    }
  }
}