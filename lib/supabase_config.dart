import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String SUPABASE_URL = 'https://cpowvsbphxtlkfxgmrjn.supabase.co';
  static const String SUPABASE_ANON_KEY =
      String.fromEnvironment('SUPABASE_KEY');

  static final supabase = Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SUPABASE_URL,
      anonKey: SUPABASE_ANON_KEY,
    );
  }
}
