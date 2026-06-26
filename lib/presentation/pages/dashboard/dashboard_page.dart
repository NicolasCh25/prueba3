import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/entities.dart';
import '../../blocs/auth_bloc.dart';
import '../../blocs/sync_bloc.dart';
import '../../blocs/vaccination_bloc.dart';
import '../admin/admin_page.dart';
import '../vaccination_form_page.dart';

class DashboardPage extends StatefulWidget {
  final AppUser user;
  const DashboardPage({super.key, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _searchQuery = '';
  String? _selectedSectorFilter;

  @override
  void initState() {
    super.initState();
    // Load initial data
    context.read<VaccinationBloc>().add(LoadVaccinationsAndSectors(widget.user));
    context.read<SyncBloc>().add(InitializeSync());
  }

  void _showRecordDetails(VaccinationRecord record, bool canEdit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(
              record.petType == 'dog' ? Icons.pets : Icons.pets_outlined,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Mascota: ${record.petName}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Picture
              if (record.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    record.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: AppColors.surfaceLight,
                      child: const Icon(Icons.broken_image, size: 40),
                    ),
                  ),
                )
              else if (record.localImagePath != null && record.localImagePath!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Builder(
                    builder: (context) {
                      final path = record.localImagePath!;
                      if (kIsWeb) {
                        if (path.startsWith('blob:') || path.startsWith('http://') || path.startsWith('https://')) {
                          return Image.network(
                            path,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 120,
                              color: AppColors.surfaceLight,
                              child: const Icon(Icons.broken_image, size: 40),
                            ),
                          );
                        } else {
                          return Container(
                            height: 120,
                            color: AppColors.surfaceLight,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image, size: 40),
                          );
                        }
                      } else {
                        return Image.file(
                          File(path),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 120,
                            color: AppColors.surfaceLight,
                            child: const Icon(Icons.broken_image, size: 40),
                          ),
                        );
                      }
                    },
                  ),
                ),
              const SizedBox(height: 16),
              _buildDetailItem('Propietario', record.ownerName),
              _buildDetailItem('Cédula', record.ownerCedula),
              _buildDetailItem('Teléfono', record.ownerPhone),
              _buildDetailItem('Edad aprox.', '${record.petAge} años'),
              _buildDetailItem('Sexo', record.petSex),
              _buildDetailItem('Vacuna', record.vaccineName),
              _buildDetailItem('Observaciones', record.observations.isNotEmpty ? record.observations : 'Ninguna'),
              _buildDetailItem('Ubicación (GPS)', 'Lat: ${record.latitude.toStringAsFixed(6)}\nLong: ${record.longitude.toStringAsFixed(6)}'),
              _buildDetailItem('Fecha', record.createdAt.toLocal().toString().substring(0, 16)),
              _buildDetailItem('Estado Sinc.', record.isSynced ? 'Sincronizado' : 'Pendiente local', isStatus: true, isSynced: record.isSynced),
            ],
          ),
        ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx, rootNavigator: true).pop();
            },
            child: const Text('Cerrar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          if (canEdit)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                minimumSize: const Size(110, 40),
              ),
              onPressed: () {
                Navigator.of(ctx, rootNavigator: true).pop();
                _openEditForm(record);
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Editar', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isStatus = false, bool isSynced = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          isStatus
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSynced ? AppColors.success.withOpacity(0.15) : AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSynced ? AppColors.success : AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  void _openEditForm(VaccinationRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VaccinationFormPage(
          currentUser: widget.user,
          existingRecord: record,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SyncBloc, SyncState>(
          listener: (context, state) {
            if (state.syncMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.syncMessage!),
                  backgroundColor: state.syncMessage!.contains('Error') ? AppColors.error : AppColors.success,
                ),
              );
              // Reload data after sync completes
              context.read<VaccinationBloc>().add(LoadVaccinationsAndSectors(widget.user));
            }
          },
        ),
        BlocListener<VaccinationBloc, VaccinationState>(
          listener: (context, state) {
            if (state is VaccinationOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                ),
              );
            } else if (state is VaccinationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
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
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<VaccinationBloc>().add(LoadVaccinationsAndSectors(widget.user));
                context.read<SyncBloc>().add(CheckPendingCountEvent());
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER BLOCK ---
                    _buildHeader(context),
                    const SizedBox(height: 12),
                    
                    // --- CONNECTION & SYNC BAR ---
                    _buildSyncStatusBar(context),
                    const SizedBox(height: 16),

                    // --- METRIC CARDS ---
                    BlocBuilder<VaccinationBloc, VaccinationState>(
                      builder: (context, state) {
                        if (state is VaccinationLoadSuccess) {
                          return _buildMetricsPanel(state);
                        }
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ));
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- SEGMENTS / METRIC BREAKDOWNS (Coordinators only) ---
                    if (widget.user.role != UserRole.vaccinator) ...[
                      BlocBuilder<VaccinationBloc, VaccinationState>(
                        builder: (context, state) {
                          if (state is VaccinationLoadSuccess) {
                            return _buildBreakdownPanel(state);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // --- RECORDS LIST ---
                    _buildRecordsSection(context),
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: widget.user.role == UserRole.vaccinator
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VaccinationFormPage(currentUser: widget.user),
                    ),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('NUEVA VACUNACIÓN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            : null,
      ),
    );
  }

  // --- SUBWIDGETS ---

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${widget.user.nombres}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.user.role.displayName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Admin Button
            if (widget.user.role != UserRole.vaccinator)
              IconButton(
                icon: const Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminPage(currentUser: widget.user),
                    ),
                  ).then((_) {
                    if (context.mounted) {
                      context.read<VaccinationBloc>().add(LoadVaccinationsAndSectors(widget.user));
                    }
                  });
                },
              ),
            // Logout
            IconButton(
              icon: const Icon(Icons.logout, color: AppColors.error, size: 24),
              onPressed: () {
                context.read<AuthBloc>().add(LogoutRequested());
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSyncStatusBar(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: state.isOnline ? AppColors.success.withOpacity(0.08) : AppColors.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: state.isOnline ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    state.isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                    color: state.isOnline ? AppColors.success : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    state.isOnline ? 'Conexión Estable' : 'Modo Offline Activado',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: state.isOnline ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
              if (state.pendingCount > 0)
                GestureDetector(
                  onTap: () {
                    if (state.isOnline) {
                      context.read<SyncBloc>().add(TriggerSyncManual());
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Necesita internet para sincronizar con la nube.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (state.isSyncing)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        else
                          const Icon(Icons.sync_problem_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${state.pendingCount} pendientes',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricsPanel(VaccinationLoadSuccess state) {
    // Metric calculation
    final records = state.records;
    final total = records.length;
    final dogs = records.where((r) => r.petType == 'dog').length;
    final cats = records.where((r) => r.petType == 'cat').length;
    final unsynced = records.where((r) => !r.isSynced).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Métricas Generales',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard('Total Vacunados', '$total', Icons.analytics_rounded, AppColors.primary),
            _buildMetricCard('Perros', '$dogs', Icons.pets, AppColors.info),
            _buildMetricCard('Gatos', '$cats', Icons.pets_outlined, AppColors.secondary),
            _buildMetricCard('Locales sin Subir', '$unsynced', Icons.cloud_upload_rounded, AppColors.accent),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.surfaceLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            val,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownPanel(VaccinationLoadSuccess state) {
    // Calculates sector and vaccinator breakdowns
    final records = state.records;
    final Map<String, int> sectorCounts = {};
    final Map<String, int> vaccinatorCounts = {};

    // Get sector name maps
    final sectorNames = {for (var s in state.allRawSectors) s.id: s.nombre};

    for (var r in records) {
      final sName = sectorNames[r.sectorId] ?? 'Desconocido';
      sectorCounts[sName] = (sectorCounts[sName] ?? 0) + 1;
      
      // Split vaccinator breakdown
      vaccinatorCounts[r.createdBy] = (vaccinatorCounts[r.createdBy] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Desglose por Sectores',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          if (sectorCounts.isEmpty)
            const Text('Sin datos disponibles', style: TextStyle(fontSize: 13, color: AppColors.textMuted))
          else
            ...sectorCounts.entries.map((e) {
              final pct = records.isEmpty ? 0.0 : e.value / records.length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                        Text('${e.value} (${(pct * 100).toStringAsFixed(0)}%)',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        color: AppColors.primary,
                        backgroundColor: AppColors.surfaceLight,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecordsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Registros de Vacunación',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            // Filter dropdown
            BlocBuilder<VaccinationBloc, VaccinationState>(
              builder: (context, state) {
                if (state is VaccinationLoadSuccess && state.sectors.isNotEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surfaceLight.withOpacity(0.5)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: AppColors.surface,
                        hint: const Text('Sectores', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        value: _selectedSectorFilter,
                        onChanged: (val) {
                          setState(() {
                            _selectedSectorFilter = val;
                          });
                        },
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Todos', style: TextStyle(fontSize: 12)),
                          ),
                          ...state.sectors.map((s) => DropdownMenuItem<String>(
                                value: s.id,
                                child: Text(s.nombre, style: const TextStyle(fontSize: 12)),
                              )),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Search bar
        TextField(
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Buscar mascota, propietario o cédula...',
            prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          ),
          onChanged: (val) {
            setState(() {
              _searchQuery = val.toLowerCase();
            });
          },
        ),
        const SizedBox(height: 16),
        // Records List view
        BlocBuilder<VaccinationBloc, VaccinationState>(
          builder: (context, state) {
            if (state is VaccinationLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            } else if (state is VaccinationLoadSuccess) {
              // Apply searches and sector filters
              var list = state.records;
              
              if (_selectedSectorFilter != null) {
                list = list.where((r) => r.sectorId == _selectedSectorFilter).toList();
              }
              if (_searchQuery.isNotEmpty) {
                list = list.where((r) {
                  return r.petName.toLowerCase().contains(_searchQuery) ||
                      r.ownerName.toLowerCase().contains(_searchQuery) ||
                      r.ownerCedula.contains(_searchQuery);
                }).toList();
              }

              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Column(
                      children: [
                        Icon(Icons.feed_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          'No se encontraron registros.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Get sector name maps
              final sectorNames = {for (var s in state.allRawSectors) s.id: s.nombre};

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final record = list[index];
                  final sName = sectorNames[record.sectorId] ?? 'Desconocido';
                  
                  // Validation of edit permission
                  bool canEdit = false;
                  if (widget.user.role == UserRole.campaignCoordinator) {
                    canEdit = true;
                  } else if (widget.user.role == UserRole.brigadeCoordinator) {
                    canEdit = true; // In his sectors, he can edit any record
                  } else if (widget.user.role == UserRole.vaccinator) {
                    canEdit = record.createdBy == widget.user.id;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: record.petType == 'dog'
                            ? AppColors.primary.withOpacity(0.15)
                            : AppColors.secondary.withOpacity(0.15),
                        child: Icon(
                          record.petType == 'dog' ? Icons.pets : Icons.pets_outlined,
                          color: record.petType == 'dog' ? AppColors.primary : AppColors.secondary,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            record.petName,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: 8),
                          if (!record.isSynced)
                            const Tooltip(
                              message: 'Pendiente de sincronizar con servidor',
                              child: Icon(Icons.cloud_upload_outlined, color: AppColors.accent, size: 16),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Dueño: ${record.ownerName}', style: const TextStyle(fontSize: 13)),
                          Text('Sector: $sName', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text('Vacuna: ${record.vaccineName}', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      onTap: () => _showRecordDetails(record, canEdit),
                    ),
                  );
                },
              );
            } else if (state is VaccinationError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: AppColors.error),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
