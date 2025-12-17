// core/widgets/permission_restricted_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockmaster/core/utils/permission_mixin.dart';
import 'package:stockmaster/presentation/cubits/auth_cubit.dart';

class PermissionRestrictedWidget extends StatelessWidget with PermissionMixin {
  final Widget child;
  final bool requiresAdmin;
  final bool requiresEdit;
  final String? adminMessage;
  final String? editMessage;
  
  const PermissionRestrictedWidget({
    super.key,
    required this.child,
    this.requiresAdmin = false,
    this.requiresEdit = false,
    this.adminMessage,
    this.editMessage,
  });
  
  @override
  Widget build(BuildContext context) {
    final hasPermission = checkPermissionBeforeNavigate(
      context,
      requiresAdmin: requiresAdmin,
      requiresEdit: requiresEdit,
    );
    
    if (!hasPermission) {
      return Container(); // O un widget vacío
    }
    
    return child;
  }
}

// Widget para mostrar solo si el usuario tiene permisos
class ConditionalPermissionWidget extends StatelessWidget with PermissionMixin {
  final WidgetBuilder builder;
  final bool requiresAdmin;
  final bool requiresEdit;
  
  const ConditionalPermissionWidget({
    super.key,
    required this.builder,
    this.requiresAdmin = false,
    this.requiresEdit = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    
    if (authCubit.currentUser == null) {
      return const SizedBox();
    }
    
    if (requiresAdmin && !authCubit.isAdmin) {
      return const SizedBox();
    }
    
    if (requiresEdit && !authCubit.canEditProduct()) {
      return const SizedBox();
    }
    
    return builder(context);
  }
}