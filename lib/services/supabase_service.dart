import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

class SupabaseService {
  static SupabaseClient? _client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase not initialized. Call SupabaseService.initialize() first.',
      );
    }
    return _client!;
  }

  static GoTrueClient get auth => client.auth;

  static SupabaseQueryBuilder from(String table) => client.from(table);
}
