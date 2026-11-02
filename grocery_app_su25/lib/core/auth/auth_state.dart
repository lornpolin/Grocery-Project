import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kSignedInKey = 'signed_in';
const String kGuestBrowsingKey = 'guest_browsing';
const String kAuthTokenKey = 'auth_token';
const String kUserIdKey = 'user_id';
const String kUserNameKey = 'user_name';
const String kUserEmailKey = 'user_email';
const String kUserPhoneKey = 'user_phone';
const String kUserAvatarKey = 'user_avatar';

/// Persisted authentication state (Sanctum bearer token + current user profile)
/// used by the router and API client.
class AuthState extends ValueNotifier<bool> {
  AuthState._() : super(false);

  static final AuthState instance = AuthState._();

  String? _token;
  String? _userId;
  String _userName = 'Guest User';
  String _userEmail = '';
  String? _userPhone;
  String? _userAvatarUrl;
  bool _guestBrowsing = false;

  bool get isSignedIn => value;
  bool get isGuestBrowsing => _guestBrowsing;
  String? get token => _token;
  String? get userId => _userId;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String? get userPhone => _userPhone;
  String? get userAvatarUrl => _userAvatarUrl;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(kAuthTokenKey);
    _userId = prefs.getString(kUserIdKey);
    _userName = prefs.getString(kUserNameKey) ?? 'Guest User';
    _userEmail = prefs.getString(kUserEmailKey) ?? '';
    _userPhone = _normalizeOptional(prefs.getString(kUserPhoneKey));
    _userAvatarUrl = _normalizeOptional(prefs.getString(kUserAvatarKey));
    _guestBrowsing = prefs.getBool(kGuestBrowsingKey) ?? false;
    value =
        prefs.getBool(kSignedInKey) ?? (_token != null && _token!.isNotEmpty);
  }

  String? _normalizeOptional(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _persistOptional(
    SharedPreferences prefs,
    String key,
    String? val,
  ) async {
    if (val != null && val.isNotEmpty) {
      await prefs.setString(key, val);
    } else {
      await prefs.remove(key);
    }
  }

  Future<void> continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    _guestBrowsing = true;
    await prefs.setBool(kGuestBrowsingKey, true);
    if (value) {
      value = false;
    }
    notifyListeners();
  }

  Future<void> setAuthSession({
    required String token,
    required String id,
    required String name,
    required String email,
    String? phone,
    String? avatarUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _token = token;
    _userId = id;
    _userName = name.isNotEmpty ? name : 'Guest User';
    _userEmail = email;
    _userPhone = _normalizeOptional(phone);
    _userAvatarUrl = _normalizeOptional(avatarUrl);
    _guestBrowsing = false;
    await prefs.setString(kAuthTokenKey, token);
    await prefs.setString(kUserIdKey, id);
    await prefs.setString(kUserNameKey, _userName);
    await prefs.setString(kUserEmailKey, _userEmail);
    await _persistOptional(prefs, kUserPhoneKey, _userPhone);
    await _persistOptional(prefs, kUserAvatarKey, _userAvatarUrl);
    await prefs.setBool(kGuestBrowsingKey, false);
    await prefs.setBool(kSignedInKey, true);
    value = true;
    notifyListeners();
  }

  Future<void> updateUserProfile({
    required String id,
    required String name,
    required String email,
    String? phone,
    String? avatarUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (id.isNotEmpty) {
      _userId = id;
      await prefs.setString(kUserIdKey, id);
    }
    if (name.isNotEmpty) _userName = name;
    if (email.isNotEmpty) _userEmail = email;
    _userPhone = _normalizeOptional(phone);
    _userAvatarUrl = _normalizeOptional(avatarUrl);
    await prefs.setString(kUserNameKey, _userName);
    await prefs.setString(kUserEmailKey, _userEmail);
    await _persistOptional(prefs, kUserPhoneKey, _userPhone);
    await _persistOptional(prefs, kUserAvatarKey, _userAvatarUrl);
    notifyListeners();
  }

  Future<void> setSignedIn(
    bool signedIn, {
    String? name,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null && name.isNotEmpty) {
      _userName = name;
      await prefs.setString(kUserNameKey, _userName);
    }
    if (email != null && email.isNotEmpty) {
      _userEmail = email;
      await prefs.setString(kUserEmailKey, _userEmail);
    }
    if (signedIn) {
      _guestBrowsing = false;
      await prefs.setBool(kGuestBrowsingKey, false);
    } else {
      _token = null;
      _userId = null;
      _userName = 'Guest User';
      _userEmail = '';
      _userPhone = null;
      _userAvatarUrl = null;
      _guestBrowsing = false;
      await prefs.remove(kAuthTokenKey);
      await prefs.remove(kUserIdKey);
      await prefs.remove(kUserNameKey);
      await prefs.remove(kUserEmailKey);
      await prefs.remove(kUserPhoneKey);
      await prefs.remove(kUserAvatarKey);
      await prefs.setBool(kGuestBrowsingKey, false);
    }
    await prefs.setBool(kSignedInKey, signedIn);
    value = signedIn;
    notifyListeners();
  }

  Future<void> clearSession() async {
    await setSignedIn(false);
  }
}
