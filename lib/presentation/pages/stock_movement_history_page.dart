import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockmaster/data/models/stock_movement_model.dart';
import 'package:stockmaster/presentation/cubits/stock_movement_cubit.dart';

class StockMovementHistoryPage extends StatefulWidget {
  final int? productId;

  const StockMovementHistoryPage({super.key, this.productId});

  @override
  State<StockMovementHistoryPage> createState() => _StockMovementHistoryPageState();
}

class _StockMovementHistoryPageState extends State<StockMovementHistoryPage> {

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  void _loadMovements() {
    if (widget.productId != null) {
      context.read<StockMovementCubit>().loadMovementsByProduct(widget.productId!);
    } else {
      context.read<StockMovementCubit>().loadAllMovements();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Movimientos'),
        actions: [
          // Filtro por tipo
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
              });
              context.read<StockMovementCubit>().filterMovementsByType(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Todos los movimientos')),
              const PopupMenuItem(value: 'entry', child: Text('Solo Entradas')),
              const PopupMenuItem(value: 'exit', child: Text('Solo Salidas')),
              const PopupMenuItem(value: 'adjustment', child: Text('Solo Ajustes')),
            ],
            child: const Icon(Icons.filter_list),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMovements,
          ),
        ],
      ),
      body: BlocBuilder<StockMovementCubit, StockMovementState>(
        builder: (context, state) {
          if (state is StockMovementLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StockMovementError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadMovements,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is StockMovementLoaded) {
            final movements = state.movements;

            if (movements.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No hay movimientos registrados'),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: movements.length,
              itemBuilder: (context, index) {
                final movement = movements[index];
                return _buildMovementItem(movement);
              },
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildMovementItem(StockMovementModel movement) {
    Color getColorByType(String type) {
      switch (type) {
        case 'entry':
          return Colors.green;
        case 'exit':
          return Colors.red;
        case 'adjustment':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    IconData getIconByType(String type) {
      switch (type) {
        case 'entry':
          return Icons.arrow_downward;
        case 'exit':
          return Icons.arrow_upward;
        case 'adjustment':
          return Icons.adjust;
        default:
          return Icons.question_mark;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: getColorByType(movement.type).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            getIconByType(movement.type),
            color: getColorByType(movement.type),
            size: 20,
          ),
        ),
        title: Text(
          movement.displayQuantity,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: getColorByType(movement.type),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(movement.reason),
            const SizedBox(height: 4),
            Text(
              'Por: ${movement.userName}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'Ref: ${movement.reference.isNotEmpty ? movement.reference : "N/A"}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${movement.previousStock} → ${movement.newStock}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(movement.date),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}