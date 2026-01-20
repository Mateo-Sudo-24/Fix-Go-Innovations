import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== REGISTRO ====================
  Future<Map<String, dynamic>> register(UserModel user, String password) async {
    try {
      print('📝 Iniciando registro para: ${user.email}');
      
      // 1. Crear usuario en Supabase Auth
      final AuthResponse authResponse = await _supabase.auth.signUp(
        email: user.email,
        password: password,
      );

      if (authResponse.user == null) {
        return {
          'success': false,
          'message': 'Error al crear usuario. Verifica tu email.',
        };
      }

      print('✅ Usuario creado en Auth: ${authResponse.user!.id}');

      // 2. Crear perfil en user_profiles
      final profileData = {
        'id': authResponse.user!.id,
        'email': user.email,
        'full_name': user.fullName,
        'phone': user.phone,
        'role': user.role.name,
        'address': user.address,
        'is_verified': false,
      };

      await _supabase.from('user_profiles').insert(profileData);
      print('✅ Perfil creado en user_profiles');

      // 3. Si es técnico, crear registro adicional
      if (user.role == UserRole.technician && user.specialty != null) {
        // Primero, buscar o crear la especialidad
        final specialtyResponse = await _supabase
            .from('specialties')
            .select('id')
            .eq('name', user.specialty!)
            .maybeSingle();

        int? specialtyId = specialtyResponse?['id'];

        // Si no existe la especialidad, crearla
        if (specialtyId == null) {
          final newSpecialty = await _supabase
              .from('specialties')
              .insert({'name': user.specialty!})
              .select('id')
              .single();
          specialtyId = newSpecialty['id'];
        }

        // Asociar técnico con especialidad
        await _supabase.from('technician_specialties').insert({
          'technician_id': authResponse.user!.id,
          'specialty_id': specialtyId,
          'experience_years': 0,
        });

        // Crear registro de verificación pendiente
        await _supabase.from('technician_verification').insert({
          'technician_id': authResponse.user!.id,
          'status': 'pending',
        });

        print('✅ Datos de técnico creados');
      }

      return {
        'success': true,
        'message': 'Registro exitoso. Revisa tu email para verificar tu cuenta.',
      };
      
    } on AuthException catch (e) {
      print('❌ Error de autenticación: ${e.message}');
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      print('❌ Error inesperado: $e');
      return {
        'success': false,
        'message': 'Error al registrar usuario: ${e.toString()}',
      };
    }
  }

  // ==================== LOGIN ====================
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔐 Iniciando login para: $email');
      
      // 1. Autenticar con Supabase
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return {
          'success': false,
          'message': 'Credenciales incorrectas',
        };
      }

      print('✅ Usuario autenticado: ${response.user!.id}');

      // 2. Obtener perfil del usuario
      final profileData = await _supabase
          .from('user_profiles')
          .select('*')
          .eq('id', response.user!.id)
          .single();

      print('✅ Perfil obtenido: ${profileData['full_name']}');

      // 3. Si es técnico, obtener especialidades
      String? specialty;
      if (profileData['role'] == 'technician') {
        final techSpecialties = await _supabase
            .from('technician_specialties')
            .select('specialty_id, specialties(name)')
            .eq('technician_id', response.user!.id)
            .maybeSingle();

        if (techSpecialties != null) {
          specialty = techSpecialties['specialties']['name'];
        }
      }

      // 4. Crear modelo de usuario
      final user = UserModel(
        id: profileData['id'],
        email: profileData['email'],
        fullName: profileData['full_name'],
        role: UserRole.values.firstWhere((e) => e.name == profileData['role']),
        phone: profileData['phone'],
        address: profileData['address'],
        specialty: specialty,
        cedula: null, // Se puede agregar a la BD si lo necesitas
      );

      return {
        'success': true,
        'message': 'Login exitoso',
        'user': user,
      };
      
    } on AuthException catch (e) {
      print('❌ Error de autenticación: ${e.message}');
      return {
        'success': false,
        'message': 'Email o contraseña incorrectos',
      };
    } catch (e) {
      print('❌ Error inesperado en login: $e');
      return {
        'success': false,
        'message': 'Error al iniciar sesión: ${e.toString()}',
      };
    }
  }

  // ==================== OBTENER USUARIO ACTUAL ====================
  UserModel? getCurrentUser() {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    // Aquí deberías obtener el perfil completo de la BD
    // Por ahora retornamos null hasta que implementes el método completo
    return null;
  }

  // ==================== LOGOUT ====================
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      print('✅ Sesión cerrada correctamente');
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      rethrow;
    }
  }

  // ==================== VERIFICAR SI ESTÁ AUTENTICADO ====================
  bool isAuthenticated() {
    return _supabase.auth.currentSession != null;
  }

  // ==================== OBTENER SESIÓN ACTUAL ====================
  Session? getCurrentSession() {
    return _supabase.auth.currentSession;
  }

  // ==================== RESETEAR CONTRASEÑA ====================
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return {
        'success': true,
        'message': 'Revisa tu email para restablecer tu contraseña',
      };
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': e.message,
      };
    }
  }
}