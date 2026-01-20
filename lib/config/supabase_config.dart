// lib/config/supabase_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Métodos getter que cargan desde .env
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL']?.trim() ?? '';
    if (url.isEmpty) {
      throw Exception('❌ SUPABASE_URL no está configurado en .env');
    }
    // Verificar formato de URL
    if (!url.startsWith('https://')) {
      throw Exception('SUPABASE_URL debe comenzar con https://');
    }
    return url;
  }

  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_PUBLISHABLE_KEY']?.trim() ?? '';
    if (key.isEmpty) {
      throw Exception('❌ SUPABASE_PUBLISHABLE_KEY no está configurado en .env');
    }
    // Verificar formato básico de JWT (empieza con eyJ)
    if (!key.startsWith('eyJ')) {
      print('⚠️  La clave puede no tener el formato correcto');
    }
    return key;
  }

  // Método para validar configuración
  static void validateConfig() {
    try {
      final url = supabaseUrl;
      final key = supabaseAnonKey;
      
      print('🔧 Configuración Supabase cargada:');
      print('   URL: $url');
      print('   Key (inicio): ${key.substring(0, min(key.length, 20))}...');
      
      if (!url.contains('supabase.co')) {
        print('⚠️  La URL no parece ser de Supabase');
      }
    } catch (e) {
      print('❌ Error en configuración: $e');
      rethrow;
    }
  }
  
  static int min(int a, int b) => a < b ? a : b;
}