import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local/hive_local_datasource.dart';
import 'data/datasources/remote/supabase_service.dart';
import 'data/repositories/repositories_impl.dart';
import 'domain/repositories/repositories.dart';
import 'presentation/blocs/auth_bloc.dart';
import 'presentation/blocs/sync_bloc.dart';
import 'presentation/blocs/vaccination_bloc.dart';
import 'presentation/pages/auth/change_password_page.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/dashboard/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize local persistent Hive storage
  await HiveLocalDataSource.instance.initialize();

  // 2. Initialize remote service (Supabase client/simulator)
  await SupabaseService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(),
        ),
        RepositoryProvider<SectorRepository>(
          create: (context) => SectorRepositoryImpl(),
        ),
        RepositoryProvider<VaccinationRepository>(
          create: (context) => VaccinationRepositoryImpl(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: RepositoryProvider.of<AuthRepository>(context),
            )..add(AppStarted()),
          ),
          BlocProvider<VaccinationBloc>(
            create: (context) => VaccinationBloc(
              vaccinationRepository: RepositoryProvider.of<VaccinationRepository>(context),
              sectorRepository: RepositoryProvider.of<SectorRepository>(context),
            ),
          ),
          BlocProvider<SyncBloc>(
            create: (context) => SyncBloc(
              vaccinationRepository: RepositoryProvider.of<VaccinationRepository>(context),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Campaña de Vacunación Canina & Felina',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          home: const AppRootNavigator(),
        ),
      ),
    );
  }
}

class AppRootNavigator extends StatelessWidget {
  const AppRootNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets_rounded,
                    size: 60,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Cargando campaña de vacunación...',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is MustChangePassword) {
          return const ChangePasswordPage();
        }

        if (state is Authenticated) {
          return DashboardPage(user: state.user);
        }

        // Default fallback (Unauthenticated / AuthError)
        return const LoginPage();
      },
    );
  }
}
