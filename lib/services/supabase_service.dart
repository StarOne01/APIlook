import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/request_model.dart';
import '../utils/exceptions/service_exception.dart';

class SupabaseService {
  late final SupabaseClient client;
  final String supabaseUrl;
  final String supabaseKey;

  SupabaseService({
    required this.supabaseUrl,
    required this.supabaseKey,
  });

  User? get currentUser => client.auth.currentUser;

  Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
        // Configure client options
        debug: true,
        // Configure auth persistence
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );

      client = Supabase.instance.client;

      // Listen for auth state changes
      client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        // Handle auth state changes
      });
    } catch (e) {
      throw ServiceException('Failed to initialize Supabase: $e');
    }
  }

  Future<AuthResponse> signUp(String email, String password) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo:
            kIsWeb ? null : 'io.supabase.apilize://signup-callback',
      );
      return response;
    } catch (e) {
      throw ServiceException(
        'Failed to sign up',
        code: ServiceErrorCode.authentication,
        provider: AuthProvider.email,
        originalError: e,
      );
    }
  }

  Future<AuthResponse> signUpWithGoogle() async {
    try {
      final response = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.apilize://login-callback',
        scopes: 'email,profile',
      );
      return AuthResponse(session: null, user: null);
    } catch (e) {
      throw ServiceException(
        'Failed to sign up with Google',
        code: ServiceErrorCode.providerError,
        provider: AuthProvider.google,
        originalError: e,
      );
    }
  }

  Future<AuthResponse> signUpWithGitHub() async {
    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: 'io.supabase.apilize://login-callback',
        scopes: 'user,email',
      );
      // Return empty AuthResponse since OAuth flow is handled externally
      return AuthResponse(session: null, user: null);
    } catch (e) {
      throw ServiceException(
        'Failed to sign up with GitHub',
        code: ServiceErrorCode.providerError,
        provider: AuthProvider.github,
        originalError: e,
      );
    }
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw ServiceException(
        'Invalid credentials',
        code: ServiceErrorCode.invalidCredentials,
        provider: AuthProvider.email,
        originalError: e,
      );
    }
  }

  Future<AuthResponse> signInWithGoogle() async {
    try {
      final signInResult = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.apilize://callback',
        queryParams: {
          'access_type': 'offline',
          'prompt': 'consent',
        },
        authScreenLaunchMode: LaunchMode.inAppWebView,
      );

      if (signInResult) {
        // Return empty AuthResponse since OAuth flow is handled externally
        return AuthResponse(session: null, user: null);
      } else {
        throw ServiceException(
          'Google sign in cancelled',
          code: ServiceErrorCode.userCancelled,
          provider: AuthProvider.google,
        );
      }
    } catch (e) {
      throw ServiceException(
        'Google sign in failed',
        code: ServiceErrorCode.providerError,
        provider: AuthProvider.google,
        originalError: e,
      );
    }
  }

  Future<AuthResponse> signInWithGitHub() async {
    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: kIsWeb ? null : 'io.supabase.apilize://login-callback',
      );
      // Return empty AuthResponse since OAuth flow is handled externally
      return AuthResponse(session: null, user: null);
    } catch (e) {
      throw ServiceException(
        'GitHub sign in failed',
        code: ServiceErrorCode.providerError,
        provider: AuthProvider.github,
        originalError: e,
      );
    }
  }

  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw ServiceException(
        'Failed to sign out',
        code: ServiceErrorCode.authentication,
        originalError: e,
      );
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? null : 'io.supabase.apilize://reset-callback',
      );
    } catch (e) {
      throw ServiceException(
        'Failed to send reset email',
        code: ServiceErrorCode.providerError,
        provider: AuthProvider.email,
        originalError: e,
      );
    }
  }

  Future<void> syncData<T>(String table, List<T> items,
      {String? onConflict}) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw AuthException('User not authenticated');

      await client.from(table).upsert(
            items
                .map((item) => {
                      'user_id': userId,
                      'data': item,
                    })
                .toList(),
            onConflict: onConflict,
          );
    } catch (e) {
      throw ServiceException('Failed to sync $table: $e');
    }
  }

  Future<bool> verifyEmail(String token) async {
    try {
      await client.auth.verifyOTP(type: OtpType.email, token: token);
      return true;
    } catch (e) {
      throw ServiceException(
        'Failed to verify email',
        code: ServiceErrorCode.validation,
        provider: AuthProvider.email,
        originalError: e,
      );
    }
  }

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
