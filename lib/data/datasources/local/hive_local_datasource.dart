import 'package:hive_flutter/hive_flutter.dart';
import '../../../domain/entities/entities.dart';

class HiveLocalDataSource {
  static final HiveLocalDataSource instance = HiveLocalDataSource._internal();
  HiveLocalDataSource._internal();

  static const String _authBoxName = 'auth_box';
  static const String _sectorsBoxName = 'sectors_box';
  static const String _vaccinationsBoxName = 'vaccinations_box';

  Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(_authBoxName);
    await Hive.openBox(_sectorsBoxName);
    await Hive.openBox(_vaccinationsBoxName);
  }

  // --- AUTH SERVICES ---
  Future<void> saveCurrentUser(AppUser user) async {
    final box = Hive.box(_authBoxName);
    await box.put('current_user', user.toMap());
  }

  Future<AppUser?> getCurrentUser() async {
    final box = Hive.box(_authBoxName);
    final data = box.get('current_user');
    if (data == null) return null;
    // Hive maps might have dynamic keys/values, cast it safely
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    return AppUser.fromMap(map);
  }

  Future<void> clearSession() async {
    final box = Hive.box(_authBoxName);
    await box.clear();
  }

  // --- SECTORS SERVICES ---
  Future<void> saveSectors(List<Sector> sectors) async {
    final box = Hive.box(_sectorsBoxName);
    await box.clear();
    final data = sectors.map((e) => e.toMap()).toList();
    await box.put('sectors_list', data);
  }

  Future<List<Sector>> getSectors() async {
    final box = Hive.box(_sectorsBoxName);
    final data = box.get('sectors_list');
    if (data == null) return [];
    final List<dynamic> list = data;
    return list.map((e) => Sector.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> addLocalSector(Sector sector) async {
    final sectors = await getSectors();
    sectors.add(sector);
    await saveSectors(sectors);
  }

  // --- VACCINATION SERVICES ---
  Future<void> saveVaccinationRecord(VaccinationRecord record) async {
    final box = Hive.box(_vaccinationsBoxName);
    await box.put(record.id, record.toMap());
  }

  Future<void> saveAllVaccinationRecords(List<VaccinationRecord> records) async {
    final box = Hive.box(_vaccinationsBoxName);
    for (var r in records) {
      await box.put(r.id, r.toMap());
    }
  }

  Future<List<VaccinationRecord>> getVaccinations() async {
    final box = Hive.box(_vaccinationsBoxName);
    final records = <VaccinationRecord>[];
    for (var key in box.keys) {
      if (key == 'current_user' || key == 'sectors_list') continue; // Safety check
      final data = box.get(key);
      if (data != null) {
        records.add(VaccinationRecord.fromMap(Map<String, dynamic>.from(data)));
      }
    }
    // Sort by date descending
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  Future<List<VaccinationRecord>> getUnsyncedVaccinations() async {
    final all = await getVaccinations();
    return all.where((element) => !element.isSynced).toList();
  }

  Future<void> deleteVaccinationRecord(String id) async {
    final box = Hive.box(_vaccinationsBoxName);
    await box.delete(id);
  }
}
