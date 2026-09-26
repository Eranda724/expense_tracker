import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Simple state holder for auth-screen busy/error state.
class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._repo) : super(const AsyncData(null));
  final AuthRepository _repo;

  Future<String?> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _repo.signIn(email.trim(), password);
      state = const AsyncData(null);
      return null;
    } catch (e) {
      state = AsyncData(null);
      return _repo.mapError(e);
    }
  }

  Future<String?> signUp(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _repo.signUp(email.trim(), password);
      state = const AsyncData(null);
      return null;
    } catch (e) {
      state = const AsyncData(null);
      return _repo.mapError(e);
    }
  }

  Future<void> signOut() => _repo.signOut();
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
      return AuthController(ref.watch(authRepositoryProvider));
    });
