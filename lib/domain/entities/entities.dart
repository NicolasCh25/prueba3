enum UserRole {
  campaignCoordinator,
  brigadeCoordinator,
  vaccinator;

  String get displayName {
    switch (this) {
      case UserRole.campaignCoordinator:
        return 'Coordinador de Campaña';
      case UserRole.brigadeCoordinator:
        return 'Coordinador de Brigada';
      case UserRole.vaccinator:
        return 'Vacunador';
    }
  }

  String toJson() => name;

  static UserRole fromJson(String name) {
    return UserRole.values.firstWhere(
      (e) => e.name == name || e.toString().split('.').last == name,
      orElse: () => UserRole.vaccinator,
    );
  }
}

class AppUser {
  final String id;
  final String cedula;
  final String nombres;
  final String apellidos;
  final String telefono;
  final String email;
  final UserRole role;
  final bool isFirstLogin;

  AppUser({
    required this.id,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    required this.telefono,
    required this.email,
    required this.role,
    this.isFirstLogin = true,
  });

  String get fullName => '$nombres $apellidos';

  AppUser copyWith({
    String? id,
    String? cedula,
    String? nombres,
    String? apellidos,
    String? telefono,
    String? email,
    UserRole? role,
    bool? isFirstLogin,
  }) {
    return AppUser(
      id: id ?? this.id,
      cedula: cedula ?? this.cedula,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      role: role ?? this.role,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cedula': cedula,
      'nombres': nombres,
      'apellidos': apellidos,
      'telefono': telefono,
      'email': email,
      'role': role.toJson(),
      'is_first_login': isFirstLogin,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      cedula: map['cedula'] ?? '',
      nombres: map['nombres'] ?? '',
      apellidos: map['apellidos'] ?? '',
      telefono: map['telefono'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.fromJson(map['role'] ?? 'vaccinator'),
      isFirstLogin: map['is_first_login'] ?? true,
    );
  }
}

class Sector {
  final String id;
  final String nombre;
  final String? coordinadorBrigadaId; // null means unassigned
  final List<String> vaccinatorIds; // List of assigned vaccinator user IDs

  Sector({
    required this.id,
    required this.nombre,
    this.coordinadorBrigadaId,
    this.vaccinatorIds = const [],
  });

  Sector copyWith({
    String? id,
    String? nombre,
    String? coorId,
    List<String>? vaccinatorIds,
    bool clearCoor = false,
  }) {
    return Sector(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      coordinadorBrigadaId: clearCoor ? null : (coorId ?? this.coordinadorBrigadaId),
      vaccinatorIds: vaccinatorIds ?? this.vaccinatorIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'coordinador_brigada_id': coordinadorBrigadaId,
      'vaccinator_ids': vaccinatorIds,
    };
  }

  factory Sector.fromMap(Map<String, dynamic> map) {
    return Sector(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      coordinadorBrigadaId: map['coordinador_brigada_id'],
      vaccinatorIds: List<String>.from(map['vaccinator_ids'] ?? []),
    );
  }
}

class VaccinationRecord {
  final String id;
  final String ownerName;
  final String ownerCedula;
  final String ownerPhone;
  final String petType; // 'dog' | 'cat'
  final String petName;
  final double petAge;
  final String petSex; // 'Macho' | 'Hembra'
  final String vaccineName;
  final String observations;
  final String imageUrl; // Remote URL or empty
  final String? localImagePath; // Temporary local file path for unsynced photos
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final String createdBy; // Vaccinator ID
  final String sectorId;
  final bool isSynced;

  VaccinationRecord({
    required this.id,
    required this.ownerName,
    required this.ownerCedula,
    required this.ownerPhone,
    required this.petType,
    required this.petName,
    required this.petAge,
    required this.petSex,
    required this.vaccineName,
    required this.observations,
    required this.imageUrl,
    this.localImagePath,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.createdBy,
    required this.sectorId,
    this.isSynced = false,
  });

  VaccinationRecord copyWith({
    String? id,
    String? ownerName,
    String? ownerCedula,
    String? ownerPhone,
    String? petType,
    String? petName,
    double? petAge,
    String? petSex,
    String? vaccineName,
    String? observations,
    String? imageUrl,
    String? localImagePath,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    String? createdBy,
    String? sectorId,
    bool? isSynced,
  }) {
    return VaccinationRecord(
      id: id ?? this.id,
      ownerName: ownerName ?? this.ownerName,
      ownerCedula: ownerCedula ?? this.ownerCedula,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      petType: petType ?? this.petType,
      petName: petName ?? this.petName,
      petAge: petAge ?? this.petAge,
      petSex: petSex ?? this.petSex,
      vaccineName: vaccineName ?? this.vaccineName,
      observations: observations ?? this.observations,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      sectorId: sectorId ?? this.sectorId,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_name': ownerName,
      'owner_cedula': ownerCedula,
      'owner_phone': ownerPhone,
      'pet_type': petType,
      'pet_name': petName,
      'pet_age': petAge,
      'pet_sex': petSex,
      'vaccine_name': vaccineName,
      'observations': observations,
      'image_url': imageUrl,
      'local_image_path': localImagePath,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'sector_id': sectorId,
      'is_synced': isSynced,
    };
  }

  factory VaccinationRecord.fromMap(Map<String, dynamic> map) {
    return VaccinationRecord(
      id: map['id'] ?? '',
      ownerName: map['owner_name'] ?? '',
      ownerCedula: map['owner_cedula'] ?? '',
      ownerPhone: map['owner_phone'] ?? '',
      petType: map['pet_type'] ?? 'dog',
      petName: map['pet_name'] ?? '',
      petAge: (map['pet_age'] as num?)?.toDouble() ?? 0.0,
      petSex: map['pet_sex'] ?? 'Macho',
      vaccineName: map['vaccine_name'] ?? '',
      observations: map['observations'] ?? '',
      imageUrl: map['image_url'] ?? '',
      localImagePath: map['local_image_path'],
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      createdBy: map['created_by'] ?? '',
      sectorId: map['sector_id'] ?? '',
      isSynced: map['is_synced'] ?? false,
    );
  }
}
