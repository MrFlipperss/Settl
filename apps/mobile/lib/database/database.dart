import 'package:supabase_flutter/supabase_flutter.dart';

abstract class Database {
  SupabaseClient get client;

  Future<void> initialize();
}
