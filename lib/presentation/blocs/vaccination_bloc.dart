import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

// --- EVENTS ---
abstract class VaccinationEvent extends Equatable {
  const VaccinationEvent();
  @override
  List<Object?> get props => [];
}

class LoadVaccinationsAndSectors extends VaccinationEvent {
  final AppUser user;
  const LoadVaccinationsAndSectors(this.user);
  @override
  List<Object?> get props => [user];
}

class AddVaccinationRecordEvent extends VaccinationEvent {
  final VaccinationRecord record;
  final AppUser currentUser;
  const AddVaccinationRecordEvent(this.record, this.currentUser);
  @override
  List<Object?> get props => [record, currentUser];
}

class EditVaccinationRecordEvent extends VaccinationEvent {
  final VaccinationRecord record;
  final AppUser currentUser;
  const EditVaccinationRecordEvent(this.record, this.currentUser);
  @override
  List<Object?> get props => [record, currentUser];
}

class CreateSectorEvent extends VaccinationEvent {
  final String nombre;
  final AppUser currentUser;
  const CreateSectorEvent(this.nombre, this.currentUser);
  @override
  List<Object?> get props => [nombre, currentUser];
}

class AssignCoordinatorEvent extends VaccinationEvent {
  final String sectorId;
  final String? coorId;
  final AppUser currentUser;
  const AssignCoordinatorEvent(this.sectorId, this.coorId, this.currentUser);
  @override
  List<Object?> get props => [sectorId, coorId, currentUser];
}

class AssignVaccinatorsEvent extends VaccinationEvent {
  final String sectorId;
  final List<String> vaccinatorIds;
  final AppUser currentUser;
  const AssignVaccinatorsEvent(this.sectorId, this.vaccinatorIds, this.currentUser);
  @override
  List<Object?> get props => [sectorId, vaccinatorIds, currentUser];
}

// --- STATES ---
abstract class VaccinationState extends Equatable {
  const VaccinationState();
  @override
  List<Object?> get props => [];
}

class VaccinationInitial extends VaccinationState {}

class VaccinationLoading extends VaccinationState {}

class VaccinationLoadSuccess extends VaccinationState {
  final List<VaccinationRecord> records; // Filtered records
  final List<Sector> sectors; // Filtered sectors
  final List<VaccinationRecord> allRawRecords; // Raw for metrics
  final List<Sector> allRawSectors; // Raw sectors for campaign coordinator admin
  
  const VaccinationLoadSuccess({
    required this.records,
    required this.sectors,
    required this.allRawRecords,
    required this.allRawSectors,
  });

  @override
  List<Object?> get props => [records, sectors, allRawRecords, allRawSectors];
}

class VaccinationOperationSuccess extends VaccinationState {
  final String message;
  const VaccinationOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class VaccinationError extends VaccinationState {
  final String message;
  const VaccinationError(this.message);
  @override
  List<Object?> get props => [message];
}

// --- BLOC ---
class VaccinationBloc extends Bloc<VaccinationEvent, VaccinationState> {
  final VaccinationRepository vaccinationRepository;
  final SectorRepository sectorRepository;

  VaccinationBloc({
    required this.vaccinationRepository,
    required this.sectorRepository,
  }) : super(VaccinationInitial()) {
    on<LoadVaccinationsAndSectors>(_onLoadVaccinationsAndSectors);
    on<AddVaccinationRecordEvent>(_onAddRecord);
    on<EditVaccinationRecordEvent>(_onEditRecord);
    on<CreateSectorEvent>(_onCreateSector);
    on<AssignCoordinatorEvent>(_onAssignCoordinator);
    on<AssignVaccinatorsEvent>(_onAssignVaccinators);
  }

  Future<void> _onLoadVaccinationsAndSectors(
    LoadVaccinationsAndSectors event,
    Emitter<VaccinationState> emit,
  ) async {
    emit(VaccinationLoading());
    try {
      final allSectors = await sectorRepository.getSectors();
      final allRecords = await vaccinationRepository.getVaccinations();

      List<Sector> filteredSectors = [];
      List<VaccinationRecord> filteredRecords = [];

      final user = event.user;

      if (user.role == UserRole.campaignCoordinator) {
        // Coordinator sees EVERYTHING
        filteredSectors = allSectors;
        filteredRecords = allRecords;
      } else if (user.role == UserRole.brigadeCoordinator) {
        // Brigade Coordinator sees only sectors assigned to them
        filteredSectors = allSectors.where((s) => s.coordinadorBrigadaId == user.id).toList();
        final sectorIds = filteredSectors.map((s) => s.id).toSet();
        // and records inside those sectors
        filteredRecords = allRecords.where((r) => sectorIds.contains(r.sectorId)).toList();
      } else if (user.role == UserRole.vaccinator) {
        // Vaccinator sees only sectors they are assigned to
        filteredSectors = allSectors.where((s) => s.vaccinatorIds.contains(user.id)).toList();
        // and only records created by themselves
        filteredRecords = allRecords.where((r) => r.createdBy == user.id).toList();
      }

      emit(VaccinationLoadSuccess(
        records: filteredRecords,
        sectors: filteredSectors,
        allRawRecords: allRecords,
        allRawSectors: allSectors,
      ));
    } catch (e) {
      emit(VaccinationError('Error al cargar datos: $e'));
    }
  }

  Future<void> _onAddRecord(
    AddVaccinationRecordEvent event,
    Emitter<VaccinationState> emit,
  ) async {
    final currentState = state;
    emit(VaccinationLoading());
    try {
      await vaccinationRepository.registerVaccination(event.record);
      emit(const VaccinationOperationSuccess('Registro de vacunación guardado exitosamente.'));
      // Reload records immediately
      add(LoadVaccinationsAndSectors(event.currentUser));
    } catch (e) {
      emit(VaccinationError('Error al registrar: $e'));
      if (currentState is VaccinationLoadSuccess) emit(currentState);
    }
  }

  Future<void> _onEditRecord(
    EditVaccinationRecordEvent event,
    Emitter<VaccinationState> emit,
  ) async {
    final currentState = state;
    emit(VaccinationLoading());
    try {
      // Permission Validation Check before editing
      final record = event.record;
      final user = event.currentUser;

      bool canEdit = false;
      if (user.role == UserRole.campaignCoordinator) {
        canEdit = true;
      } else if (user.role == UserRole.brigadeCoordinator) {
        // Find if sector is under his command
        final sectors = await sectorRepository.getSectors();
        final isMySector = sectors.any((s) => s.id == record.sectorId && s.coordinadorBrigadaId == user.id);
        if (isMySector) {
          canEdit = true;
        }
      } else if (user.role == UserRole.vaccinator) {
        // Vaccinator can only edit his own records
        if (record.createdBy == user.id) {
          canEdit = true;
        }
      }

      if (!canEdit) {
        throw Exception('No tiene permisos para modificar este registro.');
      }

      await vaccinationRepository.editVaccination(record);
      emit(const VaccinationOperationSuccess('Registro actualizado exitosamente.'));
      add(LoadVaccinationsAndSectors(user));
    } catch (e) {
      emit(VaccinationError(e.toString().replaceAll('Exception: ', '')));
      if (currentState is VaccinationLoadSuccess) emit(currentState);
    }
  }

  Future<void> _onCreateSector(
    CreateSectorEvent event,
    Emitter<VaccinationState> emit,
  ) async {
    final currentState = state;
    emit(VaccinationLoading());
    try {
      if (event.currentUser.role != UserRole.campaignCoordinator) {
        throw Exception('Solo el Coordinador de Campaña puede crear sectores.');
      }
      await sectorRepository.createSector(event.nombre);
      emit(const VaccinationOperationSuccess('Sector creado exitosamente.'));
      add(LoadVaccinationsAndSectors(event.currentUser));
    } catch (e) {
      emit(VaccinationError(e.toString().replaceAll('Exception: ', '')));
      if (currentState is VaccinationLoadSuccess) emit(currentState);
    }
  }

  Future<void> _onAssignCoordinator(
    AssignCoordinatorEvent event,
    Emitter<VaccinationState> emit,
  ) async {
    final currentState = state;
    emit(VaccinationLoading());
    try {
      if (event.currentUser.role != UserRole.campaignCoordinator) {
        throw Exception('Solo el Coordinador de Campaña puede asignar coordinadores.');
      }
      await sectorRepository.assignCoordinator(event.sectorId, event.coorId);
      emit(const VaccinationOperationSuccess('Coordinador asignado exitosamente.'));
      add(LoadVaccinationsAndSectors(event.currentUser));
    } catch (e) {
      emit(VaccinationError(e.toString().replaceAll('Exception: ', '')));
      if (currentState is VaccinationLoadSuccess) emit(currentState);
    }
  }

  Future<void> _onAssignVaccinators(
    AssignVaccinatorsEvent event,
    Emitter<VaccinationState> emit,
  ) async {
    final currentState = state;
    emit(VaccinationLoading());
    try {
      if (event.currentUser.role != UserRole.brigadeCoordinator) {
        throw Exception('Solo el Coordinador de Brigada puede asignar vacunadores.');
      }
      // Check that the sector is assigned to him
      final sectors = await sectorRepository.getSectors();
      final isMySector = sectors.any((s) => s.id == event.sectorId && s.coordinadorBrigadaId == event.currentUser.id);
      if (!isMySector) {
        throw Exception('No puede asignar vacunadores a un sector que no tiene a su cargo.');
      }

      await sectorRepository.assignVaccinators(event.sectorId, event.vaccinatorIds);
      emit(const VaccinationOperationSuccess('Vacunadores asignados exitosamente.'));
      add(LoadVaccinationsAndSectors(event.currentUser));
    } catch (e) {
      emit(VaccinationError(e.toString().replaceAll('Exception: ', '')));
      if (currentState is VaccinationLoadSuccess) emit(currentState);
    }
  }
}
