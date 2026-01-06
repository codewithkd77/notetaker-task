import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initialize();
  }

  void _initialize() {
    _currentUser = SupabaseService.auth.currentUser;

    SupabaseService.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn) {
        _currentUser = session?.user;
        _errorMessage = null;
        notifyListeners();
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        notifyListeners();
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        _currentUser = session?.user;
        notifyListeners();
      }
    });
  }

  Future<bool> signUp(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final AuthResponse response = await SupabaseService.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUser = response.user;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _errorMessage = 'Sign up failed. Please try again.';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final AuthResponse response = await SupabaseService.auth
          .signInWithPassword(email: email, password: password);

      if (response.user != null) {
        _currentUser = response.user;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _errorMessage = 'Sign in failed. Please check your credentials.';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await SupabaseService.auth.signOut();

      _currentUser = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = _parseError(e);
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Parse error message from exception
  String _parseError(dynamic error) {
    if (error is AuthException) {
      return error.message;
    }

    // Check for network-related errors
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('socketexception') ||
        errorString.contains('network') ||
        errorString.contains('host lookup') ||
        errorString.contains('no address associated with hostname')) {
      return 'No internet connection. Please check your network and try again.';
    }

    return error.toString();
  }
}
