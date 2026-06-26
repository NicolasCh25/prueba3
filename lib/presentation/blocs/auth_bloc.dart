import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

// --- EVENTS ---
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  const LoginSubmitted(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class ChangePasswordSubmitted extends AuthEvent {
  final String newPassword;
  const ChangePasswordSubmitted(this.newPassword);
  @override
  List<Object?> get props => [newPassword];
}

class PasswordResetRequested extends AuthEvent {
  final String email;
  const PasswordResetRequested(this.email);
  @override
  List<Object?> get props => [email];
}

class LogoutRequested extends AuthEvent {}

class CreateUserRequested extends AuthEvent {
  final String cedula;
  final String nombres;
  final String apellidos;
  final String telefono;
  final String email;
  final UserRole role;

  const CreateUserRequested({
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    required this.telefono,
    required this.email,
    required this.role,
  });

  @override
  List<Object?> get props => [cedula, nombres, apellidos, telefono, email, role];
}

class LoadUsersRequested extends AuthEvent {}

// --- STATES ---
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Unauthenticated extends AuthState {}

class Authenticated extends AuthState {
  final AppUser user;
  const Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class MustChangePassword extends AuthState {
  final AppUser user;
  const MustChangePassword(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class UsersLoadSuccess extends Authenticated {
  final List<AppUser> users;
  const UsersLoadSuccess(this.users, AppUser currentUser) : super(currentUser);
  @override
  List<Object?> get props => [users, user];
}

class AuthOperationInProgress extends Authenticated {
  const AuthOperationInProgress(AppUser currentUser) : super(currentUser);
}

class UserCreationSuccess extends Authenticated {
  const UserCreationSuccess(AppUser currentUser) : super(currentUser);
}

class AuthActionFailure extends Authenticated {
  final String message;
  const AuthActionFailure(this.message, AppUser currentUser) : super(currentUser);
  @override
  List<Object?> get props => [message, user];
}

// --- BLOC ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<ChangePasswordSubmitted>(_onChangePasswordSubmitted);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CreateUserRequested>(_onCreateUser);
    on<LoadUsersRequested>(_onLoadUsers);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    try {
      final cachedUser = await authRepository.getCachedUser();
      if (cachedUser != null) {
        if (cachedUser.isFirstLogin) {
          emit(MustChangePassword(cachedUser));
        } else {
          emit(Authenticated(cachedUser));
        }
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.login(event.email, event.password);
      if (user.isFirstLogin) {
        emit(MustChangePassword(user));
      } else {
        emit(Authenticated(user));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      emit(Unauthenticated());
    }
  }

  Future<void> _onChangePasswordSubmitted(ChangePasswordSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.changePassword(event.newPassword);
      final cachedUser = await authRepository.getCachedUser();
      if (cachedUser != null) {
        emit(Authenticated(cachedUser));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError('No se pudo cambiar la contraseña: $e'));
    }
  }

  Future<void> _onPasswordResetRequested(PasswordResetRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.resetPassword(event.email);
      emit(Unauthenticated()); // Go back to login
    } catch (e) {
      emit(AuthError('Error al enviar correo de recuperación: $e'));
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.logout();
      emit(Unauthenticated());
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onCreateUser(CreateUserRequested event, Emitter<AuthState> emit) async {
    final currentState = state;
    if (currentState is Authenticated) {
      final currentUser = currentState.user;
      emit(AuthOperationInProgress(currentUser));
      try {
        await authRepository.createUser(
          cedula: event.cedula,
          nombres: event.nombres,
          apellidos: event.apellidos,
          telefono: event.telefono,
          email: event.email,
          role: event.role,
        );
        emit(UserCreationSuccess(currentUser));
        // Restore previous state or reload user list if possible
        if (currentState is UsersLoadSuccess) {
          add(LoadUsersRequested());
        } else {
          emit(currentState);
        }
      } catch (e) {
        emit(AuthActionFailure('Error al crear usuario: ${e.toString().replaceAll('Exception: ', '')}', currentUser));
        emit(currentState);
      }
    }
  }

  Future<void> _onLoadUsers(LoadUsersRequested event, Emitter<AuthState> emit) async {
    final currentState = state;
    if (currentState is Authenticated) {
      final currentUser = currentState.user;
      emit(AuthOperationInProgress(currentUser));
      try {
        final users = await authRepository.getUsers();
        emit(UsersLoadSuccess(users, currentUser));
      } catch (e) {
        emit(AuthActionFailure('Error al cargar usuarios: $e', currentUser));
        emit(currentState);
      }
    }
  }
}
