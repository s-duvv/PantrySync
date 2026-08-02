import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/household.dart';

class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  bool get isAuthenticated => currentUser != null;

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password, creating profile record
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );

    if (response.user != null) {
      await _ensureProfile(response.user!.id, displayName);
    }
    return response;
  }

  /// Sign out current user session
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Fetch user profile from Supabase
  Future<UserProfile?> fetchProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) {
      return await _ensureProfile(user.id, user.email?.split('@').first ?? 'User');
    }
    return UserProfile.fromJson(response);
  }

  /// Create or update profile helper
  Future<UserProfile> _ensureProfile(String userId, String displayName) async {
    final data = {
      'id': userId,
      'display_name': displayName,
      'updated_at': DateTime.now().toIso8601String(),
    };
    final response =
        await _client.from('profiles').upsert(data).select().single();
    return UserProfile.fromJson(response);
  }

  /// Create a new household for current user
  Future<Household> createHousehold(String name) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final householdResponse = await _client
        .from('households')
        .insert({'name': name})
        .select()
        .single();

    final household = Household.fromJson(householdResponse);

    // Link user profile to new household as admin
    await _client.from('profiles').update({
      'household_id': household.id,
      'role': 'admin',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);

    return household;
  }

  /// Join an existing household via ID
  Future<void> joinHousehold(String householdId) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Verify household exists
    final household = await _client
        .from('households')
        .select()
        .eq('id', householdId)
        .maybeSingle();

    if (household == null) {
      throw Exception('Household ID not found');
    }

    await _client.from('profiles').update({
      'household_id': householdId,
      'role': 'member',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);
  }
}
