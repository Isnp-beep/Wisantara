import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';
import 'i18n.dart';

const defaultBaseUrl = 'http://10.0.2.2/Wisantara/api';

/// State global: sesi pengguna, bahasa, alamat server.
class AppState extends ChangeNotifier {
  late SharedPreferences _p;
  Api api = Api(defaultBaseUrl);
  Map<String, dynamic>? user;
  String lang = 'id';
  int unread = 0;
  int tick = 0; // naik setiap ada perubahan data agar tab me-refresh

  bool get loggedIn => user != null;
  String get baseUrl => api.base;

  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    api = Api(_p.getString('base') ?? defaultBaseUrl, _p.getString('token'));
    lang = _p.getString('lang') ?? 'id';
    I18n.lang = lang;
    if (api.token != null) {
      try {
        user = Map<String, dynamic>.from(await api.get('/me'));
        if (user!['language'] != null && _p.getString('lang') == null) {
          lang = '${user!['language']}';
          I18n.lang = lang;
        }
      } on ApiException catch (e) {
        if (e.status == 401) await _clear();
      }
    }
    notifyListeners();
  }

  Future<void> _clear() async {
    api.token = null;
    user = null;
    await _p.remove('token');
  }

  Future<void> _session(dynamic res) async {
    api.token = res['token'] as String;
    user = Map<String, dynamic>.from(res['user']);
    await _p.setString('token', api.token!);
    notifyListeners();
  }

  Future<void> login(String email, String pass) async =>
      _session(await api.post('/auth/login', {'email': email, 'password': pass}));

  Future<void> register(String name, String email, String pass, String role) async =>
      _session(await api.post('/auth/register', {'name': name, 'email': email, 'password': pass, 'role': role}));

  Future<void> logout() async {
    try {
      await api.post('/auth/logout');
    } catch (_) {}
    await _clear();
    unread = 0;
    notifyListeners();
  }

  Future<void> setLang(String code) async {
    lang = code;
    I18n.lang = code;
    await _p.setString('lang', code);
    if (loggedIn) {
      try {
        user = Map<String, dynamic>.from(await api.put('/me', {'language': code}));
      } catch (_) {}
    }
    bump();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    user = Map<String, dynamic>.from(await api.put('/me', data));
    notifyListeners();
  }

  Future<void> setBaseUrl(String url) async {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    api.base = u;
    await _p.setString('base', u);
    notifyListeners();
  }

  Future<void> refreshUnread() async {
    if (!loggedIn) return;
    try {
      final r = await api.get('/notifications');
      unread = (r['unread'] as num).toInt();
      notifyListeners();
    } catch (_) {}
  }

  void bump() {
    tick++;
    notifyListeners();
  }
}
