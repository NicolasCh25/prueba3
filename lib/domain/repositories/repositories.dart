import '../entities/entities.dart';

abstract class AuthRepository {
  Future<AppUser> login(String email, String password);
  Future<void> changePassword(String newPassword);
  Future<void> resetPassword(String email);
  Future<void> logout();
  Future<AppUser?> getCachedUser();
  Future<List<AppUser>> getUsers();
  Future<AppUser> createUser({
    required String cedula,
    required String nombres,
    required String apellidos,
    required String telefono,
    required String email,
    required UserRole role,
  });
}

abstract class SectorRepository {
  Future<List<Sector>> getSectors({bool forceRefresh = false});
  Future<Sector> createSector(String nombre);
  Future<void> assignCoordinator(String sectorId, String? coorId);
  Future<void> assignVaccinators(String sectorId, List<String> vaccinatorIds);
}

abstract class VaccinationRepository {
  Future<List<VaccinationRecord>> getVaccinations({bool forceRefresh = false});
  Future<VaccinationRecord> registerVaccination(VaccinationRecord record);
  Future<VaccinationRecord> editVaccination(VaccinationRecord record);
  Future<void> syncPendingRecords();
  Future<int> getPendingSyncCount();
}
