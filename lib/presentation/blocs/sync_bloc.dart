import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/repositories/repositories.dart';

// --- EVENTS ---
abstract class SyncEvent extends Equatable {
  const SyncEvent();
  @override
  List<Object?> get props => [];
}

class InitializeSync extends SyncEvent {}

class ConnectionChangedEvent extends SyncEvent {
  final bool isOnline;
  const ConnectionChangedEvent(this.isOnline);
  @override
  List<Object?> get props => [isOnline];
}

class TriggerSyncManual extends SyncEvent {}

class CheckPendingCountEvent extends SyncEvent {}

// --- STATES ---
class SyncState extends Equatable {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final String? syncMessage;

  const SyncState({
    this.isOnline = false,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.syncMessage,
  });

  SyncState copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingCount,
    String? syncMessage,
    bool clearMessage = false,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      syncMessage: clearMessage ? null : (syncMessage ?? this.syncMessage),
    );
  }

  @override
  List<Object?> get props => [isOnline, isSyncing, pendingCount, syncMessage];
}

// --- BLOC ---
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final VaccinationRepository vaccinationRepository;
  StreamSubscription? _connectivitySubscription;

  SyncBloc({required this.vaccinationRepository}) : super(const SyncState()) {
    on<InitializeSync>(_onInitializeSync);
    on<ConnectionChangedEvent>(_onConnectionChanged);
    on<TriggerSyncManual>(_onTriggerSyncManual);
    on<CheckPendingCountEvent>(_onCheckPendingCount);
  }

  Future<void> _onInitializeSync(InitializeSync event, Emitter<SyncState> emit) async {
    // 1. Initial check
    try {
      final results = await Connectivity().checkConnectivity();
      final isOnline = results.isNotEmpty && results.any((element) => element != ConnectivityResult.none);
      
      final pendingCount = await vaccinationRepository.getPendingSyncCount();
      emit(state.copyWith(isOnline: isOnline, pendingCount: pendingCount));
      
      if (isOnline && pendingCount > 0) {
        add(TriggerSyncManual());
      }
    } catch (_) {
      // In case package doesn't support platform test environments gracefully
    }

    // 2. Start subscription
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isOnline = results.isNotEmpty && results.any((element) => element != ConnectivityResult.none);
      add(ConnectionChangedEvent(isOnline));
    });
  }

  Future<void> _onConnectionChanged(ConnectionChangedEvent event, Emitter<SyncState> emit) async {
    final pendingCount = await vaccinationRepository.getPendingSyncCount();
    final wasOffline = !state.isOnline;
    
    emit(state.copyWith(isOnline: event.isOnline, pendingCount: pendingCount));

    // Auto-sync if transition from Offline -> Online and there are pending items
    if (event.isOnline && wasOffline && pendingCount > 0) {
      add(TriggerSyncManual());
    }
  }

  Future<void> _onTriggerSyncManual(TriggerSyncManual event, Emitter<SyncState> emit) async {
    if (state.isSyncing) return;
    
    final countBefore = await vaccinationRepository.getPendingSyncCount();
    if (countBefore == 0) {
      emit(state.copyWith(pendingCount: 0));
      return;
    }

    emit(state.copyWith(isSyncing: true, clearMessage: true));
    try {
      await vaccinationRepository.syncPendingRecords();
      final countAfter = await vaccinationRepository.getPendingSyncCount();
      
      final syncedCount = countBefore - countAfter;
      String msg = '';
      if (syncedCount > 0) {
        msg = 'Sincronizados $syncedCount registros pendientes con la nube.';
      } else {
        msg = 'No se pudieron sincronizar algunos registros.';
      }
      
      emit(state.copyWith(
        isSyncing: false,
        pendingCount: countAfter,
        syncMessage: msg,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSyncing: false,
        syncMessage: 'Error al sincronizar con el servidor: $e',
      ));
    }
  }

  Future<void> _onCheckPendingCount(CheckPendingCountEvent event, Emitter<SyncState> emit) async {
    final pendingCount = await vaccinationRepository.getPendingSyncCount();
    emit(state.copyWith(pendingCount: pendingCount));
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
