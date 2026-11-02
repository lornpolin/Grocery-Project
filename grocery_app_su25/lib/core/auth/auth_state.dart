import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kSignedInKey = 'signed_in';
const String kAuthTokenKey = 'auth_token';
const String kUserIdKey = 'user_id';
const String kUserNameKey = 'user_name';
const String kUserEmailKey = 'user_email';

/// Persisted authentication state (Sanctum bearer token + current user profile)
/// used by the router and API client.
class AuthState extends ValueNotifier<bool> {
  AuthState._() : super(false);

  static final AuthState instance = AuthState._();

  String? _token;
  String? _userId;
  String _userName = 'Polin Lorn';
  String _userEmail = 'lornpolin@gmail.com';

  String? get token => _token;
  String? get userId => _userId;
  String get userName => _userName;
  String get userEmail => _userEmail;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(kAuthTokenKey);
    _userId = prefs.getString(kUserIdKey);
    _userName = prefs.getString(kUserNameKey) ?? 'Polin Lorn';
    _userEmail = prefs.getString(kUserEmailKey) ?? 'lornpolin@gmail.com';
    value = prefs.getBool(kSignedInKey) ?? (_token != null && _token!.isNotEmpty);
  }

  Future<void> setAuthSession({
    required String token,
    required String id,
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _token = token;
    _userId = id;
    _userName = name.isNotEmpty ? name : 'Polin Lorn';
    _userEmail = email.isNotEmpty ? email : 'lornpolin@gmail.com';
    await prefs.setString(kAuthTokenKey, token);
    await prefs.setString(kUserIdKey, id);
    await prefs.setString(kUserNameKey, _userName);
    await prefs.setString(kUserEmailKey, _userEmail);
    await prefs.setBool(kSignedInKey, true);
    value = true;
    notifyListeners();
  }

  Future<void> updateUserProfile({
    required String id,
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _userId = id;
    if (name.isNotEmpty) _userName = name;
    if (email.isNotEmpty) _userEmail = email;
    await prefs.setString(kUserIdKey, id);
    await prefs.setString(kUserNameKey, _userName);
    await prefs.setString(kUserEmailKey, _userEmail);
    notifyListeners();
  }

  Future<void> setSignedIn(bool signedIn, {String? name, String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null && name.isNotEmpty) {
      _userName = name;
      await prefs.setString(kUserNameKey, _userName);
    }
    if (email != null && email.isNotEmpty) {
      _userEmail = email;
      await prefs.setString(kUserEmailKey, _userEmail);
    }
    if (!signedIn) {
      _token = null;
      _userId = null;
      await prefs.remove(kAuthTokenKey);
      await prefs.remove(kUserIdKey);
    }
    await prefs.setBool(kSignedInKey, signedIn);
    value = signedIn;
    notifyListeners();
  }

  Future<void> clearSession() async {
    await setSignedIn(false);
  }
}
