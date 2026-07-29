import 'package:supabase_flutter/supabase_flutter.dart';
import 'database.dart';

class SupabaseDatabase implements Database {
  SupabaseDatabase._();

  static Future<SupabaseDatabase> init({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
        url: supabaseUrl, publishableKey: supabaseAnonKey);
    return SupabaseDatabase._();
  }

  @override
  SupabaseClient get client => Supabase.instance.client;

  @override
  Future<void> initialize() async {}
}
