// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockmaster/data/models/user_model.dart';
import 'package:stockmaster/domain/entities/dashboard_stats.dart';
import '../cubits/dashboard_cubit.dart';
import '../cubits/auth_cubit.dart';
import '../../data/models/product_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  void _loadDashboardData() {
    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;
    
    if (authState is AuthAuthenticated) {
      final allowedCategoryIds = authCubit.getAllowedCategoryIds();
      final dashboardCubit = context.read<DashboardCubit>();
      
      // Configurar datos del usuario en DashboardCubit
      dashboardCubit.setUserData(authState.user, allowedCategoryIds);
      dashboardCubit.loadDashboardData();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            if (authState is AuthAuthenticated) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dashboard'),
                  Text(
                    authState.user.role == UserRole.admin 
                      ? 'Administrador' 
                      : authState.user.role == UserRole.manager
                        ? 'Encargado'
                        : 'Trabajador',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  ),
                ],
              );
            }
            return const Text('Dashboard');
          },
        ),
        actions: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              if (authState is AuthAuthenticated && authState.user.assignedCategoryId != null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Chip(
                    label: Text('Categoría: ${authState.user.assignedCategoryId}'),
                    backgroundColor: Colors.blue.withOpacity(0.2),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }

          return BlocBuilder<DashboardCubit, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is DashboardError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${state.message}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDashboardData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              } else if (state is DashboardLoaded) {
                return _buildDashboard(context, state.stats, authState.user);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardStats stats, UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con información del usuario
          _buildUserHeader(context, user, stats),
          
          const SizedBox(height: 24),

          // Grid de estadísticas principales
          _buildStatsGrid(context, stats),
          
          const SizedBox(height: 24),

          // NUEVA SECCIÓN: Últimos productos agregados
          if (stats.latestAddedProducts.isNotEmpty)
            _buildLatestProductsSection(context, stats),

          const SizedBox(height: 24),

          // NUEVA SECCIÓN: Últimos productos con stock bajo
          if (stats.latestLowStockProducts.isNotEmpty)
            _buildLatestLowStockSection(context, stats),

          const SizedBox(height: 24),

          // NUEVA SECCIÓN: Últimos productos críticos
          if (stats.latestCriticalProducts.isNotEmpty)
            _buildLatestCriticalSection(context, stats),

          const SizedBox(height: 24),

          // Alertas de stock (sección existente)
          if (stats.lowStockProducts > 0 || stats.outOfStockProducts > 0)
            _buildStockAlerts(context, stats),
          
          const SizedBox(height: 24),

          // Productos con stock bajo (sección existente)
          if (stats.lowStockProducts > 0)
            _buildLowStockProducts(context, stats),

          const SizedBox(height: 24),

          // Métricas financieras (sección existente)
          _buildFinancialMetrics(context, stats),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, UserModel user, DashboardStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${user.roleDisplayName} • ${stats.userScope}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Resumen rápido
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStat('Productos', stats.totalProducts, Icons.inventory_2),
              _buildQuickStat('Categorías', stats.totalCategories, Icons.category),
              _buildQuickStat('Proveedores', stats.totalSuppliers, Icons.business),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, DashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          context,
          'Stock Bajo',
          stats.lowStockProducts.toString(),
          Icons.warning,
          Colors.orange,
          'Productos con stock por debajo del mínimo',
        ),
        _buildStatCard(
          context,
          'Sin Stock',
          stats.outOfStockProducts.toString(),
          Icons.error,
          Colors.red,
          'Productos agotados',
        ),
        _buildStatCard(
          context,
          'Stock Crítico',
          stats.criticalStockProducts.toString(),
          Icons.priority_high,
          Colors.deepOrange,
          'Stock menor al 20% del mínimo',
        ),
        _buildStatCard(
          context,
          'Nuevos',
          stats.recentProductsCount.toString(),
          Icons.new_releases,
          Colors.green,
          'Productos agregados esta semana',
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // NUEVO WIDGET: Sección de últimos productos agregados
  Widget _buildLatestProductsSection(BuildContext context, DashboardStats stats) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.new_releases, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Últimos Productos Agregados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Productos agregados recientemente al sistema',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ...stats.latestAddedProducts.map((product) => 
              _buildLatestProductItem(context, product, Icons.add, Colors.green)
            ),
          ],
        ),
      ),
    );
  }

  // NUEVO WIDGET: Sección de últimos productos con stock bajo
  Widget _buildLatestLowStockSection(BuildContext context, DashboardStats stats) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_down, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Últimos en Stock Bajo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Productos que recientemente alcanzaron stock bajo',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ...stats.latestLowStockProducts.map((product) => 
              _buildLatestProductItem(context, product, Icons.warning, Colors.orange)
            ),
          ],
        ),
      ),
    );
  }

  // NUEVO WIDGET: Sección de últimos productos críticos
  Widget _buildLatestCriticalSection(BuildContext context, DashboardStats stats) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.priority_high, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Últimos en Estado Crítico',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Productos que recientemente alcanzaron estado crítico',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ...stats.latestCriticalProducts.map((product) => 
              _buildLatestProductItem(context, product, Icons.priority_high, Colors.red)
            ),
          ],
        ),
      ),
    );
  }

  // NUEVO WIDGET: Item para las listas de últimos productos
  Widget _buildLatestProductItem(BuildContext context, ProductModel product, IconData icon, Color color) {
    final stockPercentage = product.minStock > 0 ? (product.stock / product.minStock) * 100 : 0;
    final isCritical = stockPercentage < 20;
    final isLowStock = product.stock <= product.minStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Código: ${product.code}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Spacer(),
                    Text(
                      'Stock: ${product.stock}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isCritical ? Colors.red : 
                               isLowStock ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: stockPercentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCritical ? Colors.red : 
                          isLowStock ? Colors.orange : Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${stockPercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Actualizado: ${_formatDate(product.updatedAt)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método auxiliar para formatear fechas
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else {
      return 'Hace ${difference.inDays} días';
    }
  }

  Widget _buildStockAlerts(BuildContext context, DashboardStats stats) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Alertas de Stock',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (stats.criticalStockProducts > 0)
              _buildAlertItem(
                'Stock Crítico',
                '${stats.criticalStockProducts} productos necesitan atención inmediata',
                Colors.red,
                Icons.priority_high,
              ),
            if (stats.outOfStockProducts > 0)
              _buildAlertItem(
                'Productos Agotados',
                '${stats.outOfStockProducts} productos sin stock',
                Colors.orange,
                Icons.error_outline,
              ),
            if (stats.lowStockProducts > 0)
              _buildAlertItem(
                'Stock Bajo',
                '${stats.lowStockProducts} productos cerca del mínimo',
                Colors.amber,
                Icons.warning,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(String title, String message, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  message,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockProducts(BuildContext context, DashboardStats stats) {
    final lowStockProducts = stats.filteredProducts
        .where((p) => p.stock <= p.minStock)
        .take(5)
        .toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Productos con Stock Bajo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...lowStockProducts.map((product) => _buildProductAlertItem(product)),
            if (lowStockProducts.length < stats.lowStockProducts)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Y ${stats.lowStockProducts - lowStockProducts.length} productos más...',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductAlertItem(ProductModel product) {
    final stockPercentage = product.minStock > 0 ? (product.stock / product.minStock) * 100 : 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Stock: ${product.stock} / Mínimo: ${product.minStock}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: stockPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    stockPercentage < 20 ? Colors.red : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetrics(BuildContext context, DashboardStats stats) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.attach_money, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Métricas Financieras',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFinancialMetric(
                  'Valor Inventario',
                  '\$${stats.totalInventoryValue.toStringAsFixed(2)}',
                  Colors.blue,
                ),
                _buildFinancialMetric(
                  'Costo Inventario',
                  '\$${stats.totalInventoryCost.toStringAsFixed(2)}',
                  Colors.orange,
                ),
                _buildFinancialMetric(
                  'Margen',
                  '${stats.profitMargin.toStringAsFixed(1)}%',
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}