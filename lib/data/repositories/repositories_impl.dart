import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/local/hive_local_datasource.dart';
import '../datasources/remote/supabase_service.dart';

class ConnectivityHelper {
  static Future<bool> hasInternet() async {
    try {
      final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
      if (results.isEmpty) return false;
      return results.any((element) => element != ConnectivityResult.none);
    } catch (e) {
      return false; // Safely default to offline on error
    }
  }
}

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseService _remoteDS = SupabaseService.instance;
  final HiveLocalDataSource _localDS = HiveLocalDataSource.instance;

  @override
  Future<AppUser> login(String email, String password) async {
    final user = await _remoteDS.signIn(email, password);
    await _localDS.saveCurrentUser(user);
    return user;
  }

  @override
  Future<void> changePassword(String newPassword) async {
    await _remoteDS.changePassword(newPassword);
    final cached = await _localDS.getCurrentUser();
    if (cached != null) {
      await _localDS.saveCurrentUser(cached.copyWith(isFirstLogin: false));
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    await _remoteDS.recoverPassword(email);
  }

  @override
  Future<void> logout() async {
    await _remoteDS.signOut();
    await _localDS.clearSession();
  }

  @override
  Future<AppUser?> getCachedUser() async {
    return await _localDS.getCurrentUser();
  }

  @override
  Future<List<AppUser>> getUsers() async {
    if (await ConnectivityHelper.hasInternet()) {
      return await _remoteDS.getUsers();
    }
    // Fallback: If offline, we return empty list or simulated users
    return [];
  }

  @override
  Future<AppUser> createUser({
    required String cedula,
    required String nombres,
    required String apellidos,
    required String telefono,
    required String email,
    required UserRole role,
  }) async {
    return await _remoteDS.createUser(
      cedula: cedula,
      nombres: nombres,
      apellidos: apellidos,
      telefono: telefono,
      email: email,
      role: role,
    );
  }
}

class SectorRepositoryImpl implements SectorRepository {
  final SupabaseService _remoteDS = SupabaseService.instance;
  final HiveLocalDataSource _localDS = HiveLocalDataSource.instance;

  @override
  Future<List<Sector>> getSectors({bool forceRefresh = false}) async {
    final isOnline = await ConnectivityHelper.hasInternet();
    if (isOnline) {
      try {
        final sectors = await _remoteDS.getSectors();
        await _localDS.saveSectors(sectors);
        return sectors;
      } catch (e) {
        // Fallback to cache if remote fails
        return await _localDS.getSectors();
      }
    }
    return await _localDS.getSectors();
  }

  @override
  Future<Sector> createSector(String nombre) async {
    if (!await ConnectivityHelper.hasInternet()) {
      throw Exception('Debe tener conexión a internet para crear sectores.');
    }
    final newSector = await _remoteDS.createSector(nombre);
    await _localDS.addLocalSector(newSector);
    return newSector;
  }

  @override
  Future<void> assignCoordinator(String sectorId, String? coorId) async {
    if (!await ConnectivityHelper.hasInternet()) {
      throw Exception('Debe tener conexión a internet para asignar brigadistas.');
    }
    await _remoteDS.assignBrigadeCoordinator(sectorId, coorId);
    
    // Update local cache
    final sectors = await _localDS.getSectors();
    final idx = sectors.indexWhere((e) => e.id == sectorId);
    if (idx != -1) {
      sectors[idx] = sectors[idx].copyWith(coorId: coorId, clearCoor: coorId == null);
      await _localDS.saveSectors(sectors);
    }
  }

  @override
  Future<void> assignVaccinators(String sectorId, List<String> vaccinatorIds) async {
    if (!await ConnectivityHelper.hasInternet()) {
      throw Exception('Debe tener conexión a internet para asignar vacunadores.');
    }
    await _remoteDS.assignVaccinatorsToSector(sectorId, vaccinatorIds);

    // Update local cache
    final sectors = await _localDS.getSectors();
    final idx = sectors.indexWhere((e) => e.id == sectorId);
    if (idx != -1) {
      sectors[idx] = sectors[idx].copyWith(vaccinatorIds: vaccinatorIds);
      await _localDS.saveSectors(sectors);
    }
  }
}

class VaccinationRepositoryImpl implements VaccinationRepository {
  final SupabaseService _remoteDS = SupabaseService.instance;
  final HiveLocalDataSource _localDS = HiveLocalDataSource.instance;

  @override
  Future<List<VaccinationRecord>> getVaccinations({bool forceRefresh = false}) async {
    final isOnline = await ConnectivityHelper.hasInternet();
    if (isOnline) {
      try {
        final records = await _remoteDS.getVaccinations();
        await _localDS.saveAllVaccinationRecords(records);
        return await _localDS.getVaccinations();
      } catch (e) {
        return await _localDS.getVaccinations();
      }
    }
    return await _localDS.getVaccinations();
  }

  @override
  Future<VaccinationRecord> registerVaccination(VaccinationRecord record) async {
    // 1. Save to local first with isSynced = false
    var localRecord = record.copyWith(isSynced: false);
    await _localDS.saveVaccinationRecord(localRecord);

    final isOnline = await ConnectivityHelper.hasInternet();
    if (isOnline) {
      try {
        // 2. Upload image to remote storage
        String finalUrl = '';
        if (localRecord.localImagePath != null && localRecord.localImagePath!.isNotEmpty) {
          finalUrl = await _remoteDS.uploadImage(localRecord.localImagePath!);
        }

        // 3. Save to Supabase remote
        final syncedRecord = localRecord.copyWith(
          imageUrl: finalUrl.isNotEmpty ? finalUrl : localRecord.imageUrl,
          isSynced: true,
          localImagePath: null, // Clear local path since it's now synced online
        );
        final result = await _remoteDS.saveVaccinationRecord(syncedRecord);

        // 4. Update local with remote confirmation
        await _localDS.saveVaccinationRecord(result);
        return result;
      } catch (e) {
        // Ignore remote fail - stays locally as unsynced
        return localRecord;
      }
    }
    return localRecord;
  }

  @override
  Future<VaccinationRecord> editVaccination(VaccinationRecord record) async {
    // Check if it was synced
    final isOnline = await ConnectivityHelper.hasInternet();
    
    // Update local cache
    await _localDS.saveVaccinationRecord(record);

    if (isOnline && record.isSynced) {
      try {
        // If image was modified locally, upload it
        String finalUrl = record.imageUrl;
        if (record.localImagePath != null && record.localImagePath!.isNotEmpty) {
          finalUrl = await _remoteDS.uploadImage(record.localImagePath!);
        }
        
        final updatedRecord = record.copyWith(
          imageUrl: finalUrl,
          localImagePath: null, // Clear local path since it's now synced/updated online!
        );
        final result = await _remoteDS.updateVaccinationRecord(updatedRecord);
        await _localDS.saveVaccinationRecord(result);
        return result;
      } catch (e) {
        // Keep modifications locally, mark as unsynced so the system re-syncs it
        final unsynced = record.copyWith(isSynced: false);
        await _localDS.saveVaccinationRecord(unsynced);
        return unsynced;
      }
    } else {
      // Mark as unsynced since it was edited in offline state
      final unsynced = record.copyWith(isSynced: false);
      await _localDS.saveVaccinationRecord(unsynced);
      return unsynced;
    }
  }

  @override
  Future<void> syncPendingRecords() async {
    if (!await ConnectivityHelper.hasInternet()) return;

    final pending = await _localDS.getUnsyncedVaccinations();
    if (pending.isEmpty) return;

    for (var record in pending) {
      try {
        String finalUrl = record.imageUrl;
        if (record.localImagePath != null && record.localImagePath!.isNotEmpty) {
          finalUrl = await _remoteDS.uploadImage(record.localImagePath!);
        }

        final syncedRecord = record.copyWith(
          imageUrl: finalUrl.isNotEmpty ? finalUrl : record.imageUrl,
          isSynced: true,
          // Clear local photo reference to free memory once uploaded
          localImagePath: null,
        );

        final result = await _remoteDS.saveVaccinationRecord(syncedRecord);
        await _localDS.saveVaccinationRecord(result);
      } catch (e) {
        // Failed syncing individual record, will try in next sync cycle
      }
    }
  }

  @override
  Future<int> getPendingSyncCount() async {
    final pending = await _localDS.getUnsyncedVaccinations();
    return pending.length;
  }
}
