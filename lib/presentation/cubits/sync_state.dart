part of 'sync_cubit.dart';

@immutable
abstract class SyncState {
  const SyncState();
}

class SyncInitial extends SyncState {}

class SyncLoading extends SyncState {}

class SyncProgress extends SyncState {
  final String message;
  final double progress;
  final Map<String, dynamic>? details;
  
  const SyncProgress({
    required this.message,
    required this.progress,
    this.details,
  });
}

class SyncSuccess extends SyncState {
  final Map<String, dynamic> result;
  
  const SyncSuccess(this.result);
}

class SyncError extends SyncState {
  final String message;
  final Map<String, dynamic>? details;
  
  const SyncError(this.message, this.details);
}