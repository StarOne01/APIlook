import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthController extends ChangeNotifier {
  final SupabaseService _supabase;
  bool isAuthenticated = false;
  String? currentEmail;

  AuthController(this._supabase);

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    await _supabase.signUp(email, password);
  }

  Future<void> signIn(String email, String password) async {
    final response = await _supabase.signInWithEmail(email, password);
    isAuthenticated = response.user != null;
    currentEmail = response.user?.email;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _supabase.signOut();
    isAuthenticated = false;
    currentEmail = null;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    final response = await _supabase.signInWithGoogle();
    isAuthenticated = response.user != null;
    currentEmail = response.user?.email;
    notifyListeners();
  }

  Future<void> signInWithGithub() async {
    final response = await _supabase.signInWithGitHub();
    isAuthenticated = response.user != null;
    currentEmail = response.user?.email;
    notifyListeners();
  }
}
