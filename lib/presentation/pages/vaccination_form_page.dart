import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/entities.dart';
import '../blocs/vaccination_bloc.dart';

class VaccinationFormPage extends StatefulWidget {
  final AppUser currentUser;
  final VaccinationRecord? existingRecord;

  const VaccinationFormPage({
    super.key,
    required this.currentUser,
    this.existingRecord,
  });

  @override
  State<VaccinationFormPage> createState() => _VaccinationFormPageState();
}

class _VaccinationFormPageState extends State<VaccinationFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Text Controllers
  final _ownerNameController = TextEditingController();
  final _ownerCedulaController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _petNameController = TextEditingController();
  final _petAgeController = TextEditingController();
  final _observationsController = TextEditingController();

  // Selectors
  String _petType = 'dog'; // 'dog' or 'cat'
  String _petSex = 'Macho'; // 'Macho' or 'Hembra'
  String _selectedVaccine = 'Antirrábica Canina';
  String? _selectedSectorId;

  // Camera & GPS State
  String? _localImagePath;
  Uint8List? _webImageBytes;
  bool _hasNewImageSelected = false;
  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _loadingLocation = false;
  final ImagePicker _picker = ImagePicker();

  final List<String> _dogVaccines = ['Antirrábica Canina', 'PentaValente', 'Sextuple', 'Parvovirus'];
  final List<String> _catVaccines = ['Antirrábica Felina', 'Triple Viral Felina', 'Leucemia Felina'];

  @override
  void initState() {
    super.initState();
    _determineInitialState();
  }

  void _determineInitialState() {
    if (widget.existingRecord != null) {
      // Edit mode: Populate values
      final rec = widget.existingRecord!;
      _ownerNameController.text = rec.ownerName;
      _ownerCedulaController.text = rec.ownerCedula;
      _ownerPhoneController.text = rec.ownerPhone;
      _petNameController.text = rec.petName;
      _petAgeController.text = rec.petAge.toString();
      _observationsController.text = rec.observations;
      _petType = rec.petType;
      _petSex = rec.petSex;
      _selectedVaccine = rec.vaccineName;
      _selectedSectorId = rec.sectorId;
      _latitude = rec.latitude;
      _longitude = rec.longitude;
      _localImagePath = rec.localImagePath;
    } else {
      // Create mode: Trigger automatic GPS tracking
      _determinePosition();
    }
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerCedulaController.dispose();
    _ownerPhoneController.dispose();
    _petNameController.dispose();
    _petAgeController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  // --- DEVICE HARDWARE & GPS SENSORS ---
  Future<void> _determinePosition() async {
    setState(() {
      _loadingLocation = true;
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Los servicios de localización están desactivados.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Los permisos de localización fueron denegados.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Los permisos de localización están denegados permanentemente.');
      }

      // Get current location
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _loadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _loadingLocation = false;
      });
      // Non-blocking warning: let user know we couldn't get GPS but still let them save
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron obtener coordenadas GPS: ${e.toString().replaceAll('Exception: ', '')}. Se guardará con coordenadas por defecto.'),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Compresses image to minimize size and network strain
        maxWidth: 1024,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _localImagePath = image.path;
            _hasNewImageSelected = true;
          });
        } else {
          setState(() {
            _localImagePath = image.path;
            _hasNewImageSelected = true;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir la cámara: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _saveForm() {
    if (_selectedSectorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un Sector/Barrio para registrar.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Validation of pet image
      if (_localImagePath == null && widget.existingRecord?.imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Es obligatorio capturar una fotografía de la mascota.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final double petAge = double.tryParse(_petAgeController.text.trim()) ?? 0.0;
      final String uid = widget.existingRecord?.id ?? 'vac-${const Uuid().v4()}';
      final DateTime createdAt = widget.existingRecord?.createdAt ?? DateTime.now();

      final record = VaccinationRecord(
        id: uid,
        ownerName: _ownerNameController.text.trim(),
        ownerCedula: _ownerCedulaController.text.trim(),
        ownerPhone: _ownerPhoneController.text.trim(),
        petType: _petType,
        petName: _petNameController.text.trim(),
        petAge: petAge,
        petSex: _petSex,
        vaccineName: _selectedVaccine,
        observations: _observationsController.text.trim(),
        imageUrl: widget.existingRecord?.imageUrl ?? '',
        localImagePath: _hasNewImageSelected 
            ? _localImagePath 
            : (widget.existingRecord?.isSynced == true ? null : _localImagePath),
        latitude: _latitude,
        longitude: _longitude,
        createdAt: createdAt,
        createdBy: widget.existingRecord?.createdBy ?? widget.currentUser.id,
        sectorId: _selectedSectorId!,
        isSynced: widget.existingRecord?.isSynced ?? false,
      );

      if (widget.existingRecord != null) {
        context.read<VaccinationBloc>().add(EditVaccinationRecordEvent(record, widget.currentUser));
      } else {
        context.read<VaccinationBloc>().add(AddVaccinationRecordEvent(record, widget.currentUser));
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingRecord != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Registro' : 'Nueva Vacunación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primary, size: 28),
            onPressed: _saveForm,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, Color(0xFF13132B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: BlocBuilder<VaccinationBloc, VaccinationState>(
          builder: (context, state) {
            if (state is VaccinationLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (state is VaccinationLoadSuccess) {
              final sectorsList = state.sectors;
              
              // Validate that the preselected sector exists in the current list
              if (_selectedSectorId != null && !sectorsList.any((s) => s.id == _selectedSectorId)) {
                _selectedSectorId = null;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- PHOTO CAPTURE MODULE ---
                      _buildPhotoSection(),
                      const SizedBox(height: 20),

                      // --- SECTOR SELECTOR ---
                      _buildSectorSelector(sectorsList),
                      const SizedBox(height: 16),

                      // --- OWNER DETAILS PANEL ---
                      _buildFormSectionHeader('Datos del Propietario'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ownerNameController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Nombre Completo del Propietario',
                          prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre del dueño es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ownerCedulaController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Cédula',
                                prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textSecondary),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Cédula requerida';
                                }
                                if (value.trim().length < 10) {
                                  return 'Mínimo 10 dígitos';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _ownerPhoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Teléfono',
                                prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Teléfono requerido';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- PET DETAILS PANEL ---
                      _buildFormSectionHeader('Datos de la Mascota'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTypeButton('dog', 'Perro', Icons.pets)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTypeButton('cat', 'Gato', Icons.pets)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _petNameController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la Mascota',
                          prefixIcon: Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre de la mascota es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _petAgeController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Edad Aprox. (Años)',
                                prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Edad requerida';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Número inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.surfaceLight.withOpacity(0.5)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor: AppColors.surface,
                                  style: const TextStyle(color: AppColors.textPrimary),
                                  value: _petSex,
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _petSex = val;
                                      });
                                    }
                                  },
                                  items: const [
                                    DropdownMenuItem(value: 'Macho', child: Text('Macho')),
                                    DropdownMenuItem(value: 'Hembra', child: Text('Hembra')),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- MEDICAL DETAILS PANEL ---
                      _buildFormSectionHeader('Detalles Médicos'),
                      const SizedBox(height: 12),
                      // Vaccine selector dependent on pet type
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceLight.withOpacity(0.5)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: AppColors.surface,
                            style: const TextStyle(color: AppColors.textPrimary),
                            value: _selectedVaccine,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedVaccine = val;
                                });
                              }
                            },
                            items: (_petType == 'dog' ? _dogVaccines : _catVaccines)
                                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _observationsController,
                        maxLines: 2,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Observaciones / Detalles clínicos',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- GEOLOCATION INFORMATION BLOCK ---
                      _buildGeolocationBox(),
                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: _saveForm,
                        child: Text(isEditing ? 'GUARDAR CAMBIOS' : 'REGISTRAR VACUNACIÓN'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return const Center(child: Text('Cargando formulario...', style: TextStyle(color: AppColors.textSecondary)));
          },
        ),
      ),
    );
  }

  // --- FIELD PARTS HELPERS ---

  Widget _buildPhotoSection() {
    final String? remoteUrl = widget.existingRecord?.imageUrl;
    final hasRemoteUrl = remoteUrl != null && remoteUrl.isNotEmpty;
    
    Widget? imageWidget;

    if (_hasNewImageSelected) {
      if (kIsWeb) {
        if (_webImageBytes != null) {
          imageWidget = Image.memory(
            _webImageBytes!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
          );
        }
      } else if (_localImagePath != null) {
        imageWidget = Image.file(
          File(_localImagePath!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
        );
      }
    } else if (hasRemoteUrl) {
      imageWidget = Image.network(
        remoteUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
      );
    } else if (_localImagePath != null) {
      if (kIsWeb) {
        imageWidget = Image.network(
          _localImagePath!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
        );
      } else {
        imageWidget = Image.file(
          File(_localImagePath!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
        );
      }
    }

    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: ClipOval(
              child: imageWidget ?? const Icon(
                Icons.camera_alt_outlined,
                size: 40,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          FloatingActionButton.small(
            onPressed: _takePicture,
            child: const Icon(Icons.add_a_photo, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorSelector(List<Sector> sectorsList) {
    if (sectorsList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No tienes sectores asignados. Pide a tu coordinador que te asigne a un barrio.',
          style: TextStyle(color: AppColors.error, fontSize: 13),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormSectionHeader('Sector / Barrio'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceLight.withOpacity(0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: AppColors.textPrimary),
              hint: const Text('Seleccionar Sector Asignado', style: TextStyle(color: AppColors.textSecondary)),
              value: _selectedSectorId,
              onChanged: (val) {
                setState(() {
                  _selectedSectorId = val;
                });
              },
              items: sectorsList
                  .map((s) => DropdownMenuItem(value: s.id, child: Text(s.nombre)))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeButton(String type, String label, IconData icon) {
    final isSelected = _petType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _petType = type;
          // Set default vaccine matching the animal type
          _selectedVaccine = type == 'dog' ? _dogVaccines[0] : _catVaccines[0];
        });
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceLight.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeolocationBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_rounded,
            color: _latitude == 0.0 ? AppColors.textMuted : AppColors.primary,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Coordenadas de Captura GPS',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                _loadingLocation
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation(AppColors.primary)),
                          ),
                          SizedBox(width: 8),
                          Text('Obteniendo ubicación...', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        ],
                      )
                    : Text(
                        _latitude == 0.0 && _longitude == 0.0
                            ? 'Pendiente de escaneo'
                            : 'Lat: ${_latitude.toStringAsFixed(6)}\nLong: ${_longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.my_location, color: AppColors.primary),
            onPressed: _determinePosition,
          ),
        ],
      ),
    );
  }

  Widget _buildFormSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        letterSpacing: 0.5,
      ),
    );
  }
}
