import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/entities.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  SupabaseClient? _client;
  bool get isRealSupabase => _client != null;

  // Configuration for real Supabase
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://edlxgqjfwkjwndewicwu.supabase.co');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVkbHhncWpmd2tqd25kZXdpY3d1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI0MjY2NDAsImV4cCI6MjA5ODAwMjY0MH0.ih_MQUCaFIvULg-acnWp6byg-I_EMiPaKFNxP22YouU');

  // Simulator state (for demo/development fallback)
  final Map<String, AppUser> _mockUsers = {};
  final List<Sector> _mockSectors = [];
  final List<VaccinationRecord> _mockVaccinations = [];
  AppUser? _currentMockUser;

  Future<void> initialize() async {
    // Attempt real initialization only if credentials are provided
    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      try {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
        );
        _client = Supabase.instance.client;
      } catch (e) {
        // Fallback to simulator
        _client = null;
      }
    }
    
    // Seed initial mock data for instant out-of-the-box usage
    _seedMockData();
  }

  void _seedMockData() {
    // Coordinador de Campaña
    final campaignCoor = AppUser(
      id: 'usr-1',
      cedula: '1723456789',
      nombres: 'María',
      apellidos: 'Espinoza',
      telefono: '0998765432',
      email: 'campana@ecuador.com',
      role: UserRole.campaignCoordinator,
      isFirstLogin: true, // Will force change password
    );
    // Coordinador de Brigada
    final brigadeCoor = AppUser(
      id: 'usr-2',
      cedula: '1787654321',
      nombres: 'Juan',
      apellidos: 'Pérez',
      telefono: '0987654321',
      email: 'brigada@ecuador.com',
      role: UserRole.brigadeCoordinator,
      isFirstLogin: true,
    );
    // Vacunador
    final vaccinator = AppUser(
      id: 'usr-3',
      cedula: '1799999999',
      nombres: 'Carlos',
      apellidos: 'Gómez',
      telefono: '0977777777',
      email: 'vacunador@ecuador.com',
      role: UserRole.vaccinator,
      isFirstLogin: true,
    );

    _mockUsers[campaignCoor.email] = campaignCoor;
    _mockUsers[brigadeCoor.email] = brigadeCoor;
    _mockUsers[vaccinator.email] = vaccinator;

    // Sectores
    _mockSectors.addAll([
      Sector(id: 'sec-1', nombre: 'Sauces (Guayaquil)', coordinadorBrigadaId: 'usr-2'),
      Sector(id: 'sec-2', nombre: 'La Mariscal (Quito)', coordinadorBrigadaId: 'usr-2'),
      Sector(id: 'sec-3', nombre: 'Centro Histórico (Quito)'),
      Sector(id: 'sec-4', nombre: 'Urdesa (Guayaquil)'),
      Sector(id: 'sec-5', nombre: 'Carapungo (Quito)'),
    ]);

    // Initial vaccination records for visualization
    _mockVaccinations.addAll([
      VaccinationRecord(
        id: 'vac-1',
        ownerName: 'Luis Anchundia',
        ownerCedula: '0922445566',
        ownerPhone: '0912345678',
        petType: 'dog',
        petName: 'Rocky',
        petAge: 2.5,
        petSex: 'Macho',
        vaccineName: 'Antirrábica Canina',
        observations: 'Mascota sana y dócil',
        imageUrl: 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=500',
        latitude: -0.180653,
        longitude: -78.467834,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        createdBy: 'usr-3',
        sectorId: 'sec-1',
        isSynced: true,
      ),
      VaccinationRecord(
        id: 'vac-2',
        ownerName: 'Ana María Romero',
        ownerCedula: '1734567890',
        ownerPhone: '0933445566',
        petType: 'cat',
        petName: 'Luna',
        petAge: 1.0,
        petSex: 'Hembra',
        vaccineName: 'Antirrábica Felina',
        observations: 'Foto obligatoria guardada',
        imageUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=500',
        latitude: -0.182390,
        longitude: -78.472890,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        createdBy: 'usr-3',
        sectorId: 'sec-2',
        isSynced: true,
      ),
    ]);
  }

  // --- AUTH METHODS ---
  Future<AppUser> signIn(String email, String password) async {
    if (isRealSupabase) {
      try {
        final response = await _client!.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (response.user == null) throw Exception('Usuario no encontrado');
        
        // Fetch profile
        final data = await _client!
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .single();
        
        return AppUser.fromMap(data);
      } catch (e) {
        throw Exception('Credenciales incorrectas o error de conexión: $e');
      }
    } else {
      // Simulate delays
      await Future.delayed(const Duration(milliseconds: 800));
      if (!_mockUsers.containsKey(email)) {
        throw Exception('El usuario no está registrado.');
      }
      if (password != 'Ecuador2026' && password != 'ClaveModificada2026') {
        throw Exception('Contraseña incorrecta.');
      }
      final user = _mockUsers[email]!;
      _currentMockUser = user;
      return user;
    }
  }

  Future<void> changePassword(String newPassword) async {
    if (isRealSupabase) {
      await _client!.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      // Update profile set isFirstLogin = false
      final userId = _client!.auth.currentUser?.id;
      if (userId != null) {
        await _client!.from('profiles').update({
          'is_first_login': false,
        }).eq('id', userId);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
      if (_currentMockUser != null) {
        final updated = _currentMockUser!.copyWith(isFirstLogin: false);
        _mockUsers[_currentMockUser!.email] = updated;
        _currentMockUser = updated;
      }
    }
  }

  Future<void> recoverPassword(String email) async {
    if (isRealSupabase) {
      await _client!.auth.resetPasswordForEmail(email);
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!_mockUsers.containsKey(email)) {
        throw Exception('El correo no se encuentra registrado.');
      }
    }
  }

  Future<void> signOut() async {
    if (isRealSupabase) {
      await _client!.auth.signOut();
    } else {
      _currentMockUser = null;
    }
  }

  // --- SECTOR METHODS ---
  Future<List<Sector>> getSectors() async {
    if (isRealSupabase) {
      final List<dynamic> response = await _client!.from('sectors').select();
      return response.map((e) => Sector.fromMap(e)).toList();
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
      return List.from(_mockSectors);
    }
  }

  Future<Sector> createSector(String nombre) async {
    if (isRealSupabase) {
      final response = await _client!.from('sectors').insert({
        'nombre': nombre,
      }).select().single();
      return Sector.fromMap(response);
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      final newSector = Sector(
        id: 'sec-${DateTime.now().millisecondsSinceEpoch}',
        nombre: nombre,
      );
      _mockSectors.add(newSector);
      return newSector;
    }
  }

  Future<void> assignBrigadeCoordinator(String sectorId, String? coorId) async {
    if (isRealSupabase) {
      await _client!.from('sectors').update({
        'coordinador_brigada_id': coorId,
      }).eq('id', sectorId);
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
      final idx = _mockSectors.indexWhere((e) => e.id == sectorId);
      if (idx != -1) {
        _mockSectors[idx] = _mockSectors[idx].copyWith(
          coorId: coorId,
          clearCoor: coorId == null,
        );
      }
    }
  }

  Future<void> assignVaccinatorsToSector(String sectorId, List<String> vaccinatorIds) async {
    if (isRealSupabase) {
      await _client!.from('sectors').update({
        'vaccinator_ids': vaccinatorIds,
      }).eq('id', sectorId);
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
      final idx = _mockSectors.indexWhere((e) => e.id == sectorId);
      if (idx != -1) {
        _mockSectors[idx] = _mockSectors[idx].copyWith(
          vaccinatorIds: vaccinatorIds,
        );
      }
    }
  }

  // --- USER MANAGEMENT METHODS ---
  Future<List<AppUser>> getUsers() async {
    if (isRealSupabase) {
      final List<dynamic> response = await _client!.from('profiles').select();
      return response.map((e) => AppUser.fromMap(e)).toList();
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
      return _mockUsers.values.toList();
    }
  }

  Future<AppUser> createUser({
    required String cedula,
    required String nombres,
    required String apellidos,
    required String telefono,
    required String email,
    required UserRole role,
  }) async {
    if (isRealSupabase) {
      try {
        final response = await _client!.functions.invoke(
          'create-user',
          body: {
            'cedula': cedula,
            'nombres': nombres,
            'apellidos': apellidos,
            'telefono': telefono,
            'email': email,
            'role': role.toJson(),
          },
        );

        if (response.status != 200) {
          final errorMsg = response.data is Map ? response.data['error'] : 'Error del servidor al crear usuario.';
          throw Exception(errorMsg);
        }

        return AppUser.fromMap(response.data as Map<String, dynamic>);
      } catch (e) {
        throw Exception(e.toString().replaceAll('Exception: ', ''));
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      if (_mockUsers.values.any((u) => u.cedula == cedula || u.email == email)) {
        throw Exception('Cédula o Correo ya registrados.');
      }
      final newUser = AppUser(
        id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
        cedula: cedula,
        nombres: nombres,
        apellidos: apellidos,
        telefono: telefono,
        email: email,
        role: role,
        isFirstLogin: true,
      );
      _mockUsers[email] = newUser;
      return newUser;
    }
  }

  // --- VACCINATION RECORD METHODS ---
  Future<List<VaccinationRecord>> getVaccinations() async {
    if (isRealSupabase) {
      final List<dynamic> response = await _client!.from('vaccinations').select();
      return response.map((e) => VaccinationRecord.fromMap(e)).toList();
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
      return List.from(_mockVaccinations);
    }
  }  Future<String> uploadImage(String filePath) async {
    if (filePath.isEmpty) return '';

    if (isRealSupabase) {
      final fileName = 'pet_${DateTime.now().millisecondsSinceEpoch}.jpg';
      if (kIsWeb) {
        final xfile = XFile(filePath);
        final bytes = await xfile.readAsBytes();
        await _client!.storage.from('pet-images').uploadBinary(fileName, bytes);
      } else {
        final file = File(filePath);
        if (!await file.exists()) return '';
        await _client!.storage.from('pet-images').upload(fileName, file);
      }
      final String publicUrl = _client!.storage.from('pet-images').getPublicUrl(fileName);
      return publicUrl;
    } else {
      await Future.delayed(const Duration(seconds: 1));
      // Return a beautiful mock placeholder image of a dog or cat based on time
      return filePath.contains('cat') || DateTime.now().second % 2 == 0
          ? 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=500'
          : 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=500';
    }
  }
  Future<VaccinationRecord> saveVaccinationRecord(VaccinationRecord record) async {
    if (isRealSupabase) {
      final response = await _client!.from('vaccinations').insert(
        record.copyWith(isSynced: true).toMap(),
      ).select().single();
      return VaccinationRecord.fromMap(response);
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      final syncedRecord = record.copyWith(isSynced: true);
      _mockVaccinations.add(syncedRecord);
      return syncedRecord;
    }
  }

  Future<VaccinationRecord> updateVaccinationRecord(VaccinationRecord record) async {
    if (isRealSupabase) {
      final response = await _client!
          .from('vaccinations')
          .update(record.toMap())
          .eq('id', record.id)
          .select()
          .single();
      return VaccinationRecord.fromMap(response);
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      final idx = _mockVaccinations.indexWhere((e) => e.id == record.id);
      if (idx != -1) {
        _mockVaccinations[idx] = record;
      }
      return record;
    }
  }
}
