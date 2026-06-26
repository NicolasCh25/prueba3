import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/entities.dart';
import '../../blocs/auth_bloc.dart';
import '../../blocs/vaccination_bloc.dart';

class AdminPage extends StatefulWidget {
  final AppUser currentUser;

  const AdminPage({super.key, required this.currentUser});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Fetch users list and reload vaccination/sectors context
    context.read<AuthBloc>().add(LoadUsersRequested());
    context.read<VaccinationBloc>().add(LoadVaccinationsAndSectors(widget.currentUser));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateSectorDialog() {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Fetch already registered sectors to prevent duplicate names locally
    final vacState = context.read<VaccinationBloc>().state;
    final List<Sector> allSectors = vacState is VaccinationLoadSuccess ? vacState.allRawSectors : [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Crear Nuevo Sector', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Nombre del Sector / Barrio',
              hintText: 'Ej. La Mariscal',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre es obligatorio';
              }
              final cleanVal = value.trim().toLowerCase();
              if (allSectors.any((s) => s.nombre.toLowerCase() == cleanVal)) {
                return 'Este sector ya está registrado';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44), backgroundColor: AppColors.primary),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<VaccinationBloc>().add(
                      CreateSectorEvent(nameController.text.trim(), widget.currentUser),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Crear', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _showCreateUserDialog() {
    final formKey = GlobalKey<FormState>();
    final cedulaController = TextEditingController();
    final namesController = TextEditingController();
    final lastnamesController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    // Default password description for UI
    const defaultPasswordInfo = 'La contraseña inicial por defecto será: Ecuador2026';

    // Role is locked based on current user role
    final UserRole roleToCreate = widget.currentUser.role == UserRole.campaignCoordinator
        ? UserRole.brigadeCoordinator
        : UserRole.vaccinator;

    // Fetch already registered users from AuthBloc state to prevent duplicate emails/cedulas locally
    final authState = context.read<AuthBloc>().state;
    final List<AppUser> allUsers = authState is UsersLoadSuccess ? authState.users : [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Registrar ${roleToCreate.displayName}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  defaultPasswordInfo,
                  style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: cedulaController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Cédula de Identidad'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Requerido';
                    if (val.trim().length < 10) return 'Mínimo 10 dígitos';
                    final cleanVal = val.trim();
                    if (allUsers.any((u) => u.cedula == cleanVal)) {
                      return 'Esta cédula ya está registrada';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: namesController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Nombres'),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lastnamesController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Apellidos'),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Teléfono Celular'),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Requerido';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                      return 'Ingrese un correo válido';
                    }
                    final cleanVal = val.trim().toLowerCase();
                    if (allUsers.any((u) => u.email.toLowerCase() == cleanVal)) {
                      return 'Este correo ya está registrado';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44), backgroundColor: AppColors.primary),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<AuthBloc>().add(
                      CreateUserRequested(
                        cedula: cedulaController.text.trim(),
                        nombres: namesController.text.trim(),
                        apellidos: lastnamesController.text.trim(),
                        telefono: phoneController.text.trim(),
                        email: emailController.text.trim(),
                        role: roleToCreate,
                      ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Guardar', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _showAssignCoordinatorDialog(Sector sector, List<AppUser> allUsers) {
    // Filter only brigade coordinators
    final coordinators = allUsers.where((u) => u.role == UserRole.brigadeCoordinator).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Asignar Coordinador a: ${sector.nombre}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: coordinators.isEmpty
            ? const Text('No hay Coordinadores de Brigada registrados en el sistema.', style: TextStyle(color: AppColors.textSecondary))
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: coordinators.length + 1,
                  itemBuilder: (c, idx) {
                    if (idx == 0) {
                      return ListTile(
                        title: const Text('Desasignar / Dejar vacío', style: TextStyle(color: AppColors.error)),
                        onTap: () {
                          context.read<VaccinationBloc>().add(
                                AssignCoordinatorEvent(sector.id, null, widget.currentUser),
                              );
                          Navigator.pop(ctx);
                        },
                      );
                    }
                    final coor = coordinators[idx - 1];
                    return ListTile(
                      title: Text(coor.fullName, style: const TextStyle(color: AppColors.textPrimary)),
                      subtitle: Text('Cédula: ${coor.cedula}', style: const TextStyle(color: AppColors.textSecondary)),
                      trailing: sector.coordinadorBrigadaId == coor.id ? const Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () {
                        context.read<VaccinationBloc>().add(
                              AssignCoordinatorEvent(sector.id, coor.id, widget.currentUser),
                            );
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _showAssignVaccinatorsDialog(Sector sector, List<AppUser> allUsers) {
    // Filter only vaccinators
    final vaccinators = allUsers.where((u) => u.role == UserRole.vaccinator).toList();
    List<String> tempSelectedIds = List.from(sector.vaccinatorIds);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (sbContext, sbSetState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Asignar Vacunadores a: ${sector.nombre}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: vaccinators.isEmpty
              ? const Text('No hay Vacunadores registrados.', style: TextStyle(color: AppColors.textSecondary))
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: vaccinators.length,
                    itemBuilder: (c, idx) {
                      final vacc = vaccinators[idx];
                      final isSelected = tempSelectedIds.contains(vacc.id);

                      return CheckboxListTile(
                        title: Text(vacc.fullName, style: const TextStyle(color: AppColors.textPrimary)),
                        subtitle: Text('Cédula: ${vacc.cedula}', style: const TextStyle(color: AppColors.textSecondary)),
                        value: isSelected,
                        activeColor: AppColors.primary,
                        onChanged: (checked) {
                          sbSetState(() {
                            if (checked == true) {
                              tempSelectedIds.add(vacc.id);
                            } else {
                              tempSelectedIds.remove(vacc.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                context.read<VaccinationBloc>().add(
                      AssignVaccinatorsEvent(sector.id, tempSelectedIds, widget.currentUser),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthActionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        } else if (state is UserCreationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario creado de forma exitosa.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      child: BlocListener<VaccinationBloc, VaccinationState>(
        listener: (context, state) {
          if (state is VaccinationOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
            );
          } else if (state is VaccinationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Panel de Administración'),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(icon: Icon(Icons.map_rounded), text: 'Sectores'),
                Tab(icon: Icon(Icons.people_alt_rounded), text: 'Usuarios'),
              ],
            ),
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
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSectorsTab(),
                _buildUsersTab(),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (_tabController.index == 0) {
                if (widget.currentUser.role == UserRole.campaignCoordinator) {
                  _showCreateSectorDialog();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Solo el Coordinador de Campaña puede crear nuevos sectores.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } else {
                _showCreateUserDialog();
              }
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // --- SECTORS PANEL ---
  Widget _buildSectorsTab() {
    return BlocBuilder<VaccinationBloc, VaccinationState>(
      builder: (context, state) {
        if (state is VaccinationLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (state is VaccinationLoadSuccess) {
          // Campaign Coordinator sees allRawSectors, Brigade Coordinator sees only sectors assigned to them
          final list = widget.currentUser.role == UserRole.campaignCoordinator ? state.allRawSectors : state.sectors;

          if (list.isEmpty) {
            return const Center(
              child: Text(
                'No hay sectores disponibles.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              final List<AppUser> allUsers = authState is UsersLoadSuccess ? authState.users : [];
              final userNames = {for (var u in allUsers) u.id: u.fullName};

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final sector = list[index];
                  final String coorName = sector.coordinadorBrigadaId == null
                      ? 'No Asignado'
                      : (userNames[sector.coordinadorBrigadaId] ?? 'Cargando...');

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                sector.nombre,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const Icon(Icons.map_outlined, color: AppColors.primary, size: 20),
                            ],
                          ),
                          const Divider(height: 20, color: AppColors.surfaceLight),
                          Text(
                            'Coordinador de Brigada:',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            coorName,
                            style: TextStyle(
                              fontSize: 14,
                              color: sector.coordinadorBrigadaId == null ? AppColors.accent : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Vacunadores Asignados:',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${sector.vaccinatorIds.length} vacunadores',
                            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (widget.currentUser.role == UserRole.campaignCoordinator)
                                OutlinedButton.icon(
                                  onPressed: () => _showAssignCoordinatorDialog(sector, allUsers),
                                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                                  label: const Text('Asignar Coordinador', style: TextStyle(fontSize: 12)),
                                ),
                              if (widget.currentUser.role == UserRole.brigadeCoordinator)
                                OutlinedButton.icon(
                                  onPressed: () => _showAssignVaccinatorsDialog(sector, allUsers),
                                  icon: const Icon(Icons.group_add_rounded, size: 16),
                                  label: const Text('Asignar Vacunadores', style: TextStyle(fontSize: 12)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // --- USERS PANEL ---
  Widget _buildUsersTab() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthOperationInProgress) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (state is UsersLoadSuccess) {
          // Filter users list to show only relevant ones based on logged in role
          // Campaign Coordinator sees all users except campaign coordinators
          // Brigade Coordinator sees only vaccinators
          var list = state.users;
          if (widget.currentUser.role == UserRole.campaignCoordinator) {
            list = list.where((u) => u.role != UserRole.campaignCoordinator).toList();
          } else if (widget.currentUser.role == UserRole.brigadeCoordinator) {
            list = list.where((u) => u.role == UserRole.vaccinator).toList();
          }

          if (list.isEmpty) {
            return const Center(
              child: Text(
                'No hay usuarios registrados.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final user = list[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: user.role == UserRole.brigadeCoordinator
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.info.withOpacity(0.15),
                    child: Icon(
                      user.role == UserRole.brigadeCoordinator ? Icons.supervised_user_circle : Icons.person,
                      color: user.role == UserRole.brigadeCoordinator ? AppColors.primary : AppColors.info,
                    ),
                  ),
                  title: Text(
                    user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Cédula: ${user.cedula}', style: const TextStyle(fontSize: 12)),
                      Text('Correo: ${user.email}', style: const TextStyle(fontSize: 12)),
                      Text('Teléfono: ${user.telefono}', style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user.role.displayName,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return const Center(
          child: Text('Cargando lista de usuarios...', style: TextStyle(color: AppColors.textSecondary)),
        );
      },
    );
  }
}
