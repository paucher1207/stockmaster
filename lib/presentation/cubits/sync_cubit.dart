import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockmaster/data/firebase/sync_service.dart';

part 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  final SyncService _syncService;
  
  SyncCubit(this._syncService) : super(SyncInitial());
  
  Future<void> testSync() async {
    emit(SyncLoading());
    
    try {
      final result = await _syncService.debugSync();
      
      if (result['success'] == true) {
        emit(SyncSuccess(result));
      } else {
        emit(SyncError(result['error'] ?? 'Error desconocido', result));
      }
    } catch (e) {
      emit(SyncError('Error en testSync: $e', {'error': e.toString()}));
    }
  }

  Future<void> uploadAllLocalData() async {
    emit(SyncLoading());
    
    try {
      final result = await _syncService.uploadAllLocalDataWithProgress();
      
      if (result['success'] == true) {
        emit(SyncSuccess(result));
      } else {
        emit(SyncError(result['error'] ?? 'Error subiendo datos', result));
      }
    } catch (e) {
      emit(SyncError('Error en uploadAllLocalData: $e', {'error': e.toString()}));
    }
  }
    
  Future<void> quickSync() async {
    emit(SyncLoading());
    
    try {
      await _syncService.quickSync();
      emit(const SyncSuccess({
        'success': true,
        'message': 'Sincronización rápida completada'
      }));
    } catch (e) {
      emit(SyncError('Error en quickSync: $e', {'error': e.toString()}));
    }
  }
  
  Future<void> syncBidirectional() async {
    emit(SyncLoading());
    
    try {
      await _syncService.syncBidirectional();
      emit(const SyncSuccess({
        'success': true,
        'message': 'Sincronización bidireccional completada'
      }));
    } catch (e) {
      emit(SyncError('Error en syncBidirectional: $e', {'error': e.toString()}));
    }
  }
  
  Future<void> getUploadStats() async {
    emit(SyncLoading());
    
    try {
      final stats = await _syncService.getUploadStats();
      emit(SyncSuccess({
        'success': true,
        'message': 'Estadísticas de subida',
        'stats': stats,
      }));
    } catch (e) {
      emit(SyncError('Error obteniendo estadísticas: $e', null));
    }
  }
  
  void reset() {
    emit(SyncInitial());
  }
}