import '../models/user_model.dart';

class AuthService {
  // Simulación de base de datos en memoria
  static final List<UserModel> _users = [];
  static UserModel? _currentUser;

  // Registro de usuario
  Future<Map<String, dynamic>> register(UserModel user, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simular llamada API
    
    // Verificar si el email ya existe
    if (_users.any((u) => u.email == user.email)) {
      return {'success': false, 'message': 'El email ya está registrado'};
    }
    
    _users.add(user);
    return {'success': true, 'message': 'Registro exitoso'};
  }

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simular llamada API
    
    try {
      final user = _users.firstWhere((u) => u.email == email);
      _currentUser = user;
      return {
        'success': true,
        'message': 'Login exitoso',
        'user': user,
      };
    } catch (e) {
      return {'success': false, 'message': 'Credenciales incorrectas'};
    }
  }

  // Obtener usuario actual
  UserModel? getCurrentUser() => _currentUser;

  // Logout
  void logout() {
    _currentUser = null;
  }

  // Verificar si está autenticado
  bool isAuthenticated() => _currentUser != null;
}