import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

/// Service class for Supabase initialization and access
///
/// Provides a centralized way to access Supabase client
/// Initialize this service before using any Supabase features
class SupabaseService {
  static SupabaseClient? _client;

  /// Initialize Supabase
  /// Call this once at app startup before runApp()
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  /// Get the Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase not initialized. Call SupabaseService.initialize() first.',
      );
    }
    return _client!;
  }

  /// Convenience getter for auth
  static GoTrueClient get auth => client.auth;

  /// Convenience getter for database
  static SupabaseQueryBuilder from(String table) => client.from(table);
}
