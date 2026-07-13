import 'package:flutter/foundation.dart';
import '../data/models/user_model.dart';
import '../data/models/subscription_model.dart';
import '../data/services/api_service.dart';

enum AuthState { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _api = ApiService();

  AuthState _state = AuthState.unknown;
  UserModel? _user;
  SubscriptionModel? _subscription;
  String? _errorMessage;

  AuthState get state => _state;
  UserModel? get user => _user;
  SubscriptionModel? get subscription => _subscription;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get hasActiveSubscription =>
      _subscription != null && _subscription!.isActive;

  void _init() {
    _api.init();
    _api.onUnauthorized = _handleUnauthorized;
  }

  Future<void> checkSession() async {
    _init();
    final hasToken = await _api.hasToken();
    if (!hasToken) {
      _state = AuthState.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      _user = await _api.getMe();
      _state = AuthState.authenticated;
      _loadSubscription();
    } catch (_) {
      await _api.clearAuth();
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    try {
      final data = await _api.login(email, password);
      await _api.saveToken(data['token'] as String);
      final user = UserModel.fromJson(
          data['user'] as Map<String, dynamic>);
      await _api.saveUserId(user.id);
      _user = user;
      _state = AuthState.authenticated;
      _loadSubscription();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _api.friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _errorMessage = null;
    try {
      final data = await _api.register(name, email, password);
      await _api.saveToken(data['token'] as String);
      final user = UserModel.fromJson(
          data['user'] as Map<String, dynamic>);
      await _api.saveUserId(user.id);
      _user = user;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _api.friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.clearAuth();
    _user = null;
    _subscription = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  void _handleUnauthorized() {
    _user = null;
    _subscription = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<void> _loadSubscription() async {
    try {
      _subscription = await _api.getSubscription();
      notifyListeners();
    } catch (_) {}
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
