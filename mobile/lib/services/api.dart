import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _baseUrl = 'https://cantine-vatel.duckdns.org/api';
const _tokenKey = 'auth_token';
const _userKey = 'auth_user';

abstract class AuthRepository {
  Future<Map<String, dynamic>> login(String matricule, String password);
  Future<void> logout();
  Future<String?> getToken();
}

class ApiService implements AuthRepository {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(_AuthInterceptor());
  }

  @override
  Future<Map<String, dynamic>> login(String matricule, String password) async {
    final resp = await _dio.post('/auth/login', data: {
      'matricule': matricule,
      'password': password,
    });
    final token = resp.data['token'] as String;
    final user = resp.data['user'] as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, _encodeUser(user));
    return resp.data as Map<String, dynamic>;
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    return _decodeUser(raw);
  }

  Future<Map<String, dynamic>> getMe() async {
    final token = await getToken();
    final resp = await _dio.get('/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMenusWeek({String? date}) async {
    final token = await getToken();
    final resp = await _dio.get('/menus/week',
        queryParameters: date != null ? {'date': date} : null,
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDish(int id) async {
    final token = await getToken();
    final resp = await _dio.get('/dishes/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reserve(int dishId) async {
    final token = await getToken();
    final resp = await _dio.post('/reservations',
        data: {'dish_id': dishId},
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTransactions({String? type}) async {
    final token = await getToken();
    final resp = await _dio.get('/transactions',
        queryParameters: type != null ? {'type': type} : null,
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> initiateRecharge({
    required int amount,
    required String phone,
    required String channel,
    int? studentId,
  }) async {
    final token = await getToken();
    final path = studentId != null ? '/parent/recharge' : '/recharge/initiate';
    final body = {
      'amount': amount,
      'phone': phone,
      'channel': channel,
      if (studentId != null) 'student_id': studentId,
    };
    final resp = await _dio.post(path,
        data: body,
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getParentChildren() async {
    final token = await getToken();
    final resp = await _dio.get('/parent/children',
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getParentTransactions({int? studentId}) async {
    final token = await getToken();
    final resp = await _dio.get('/parent/transactions',
        queryParameters: studentId != null ? {'student_id': studentId} : null,
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return resp.data as Map<String, dynamic>;
  }

  String _encodeUser(Map<String, dynamic> user) =>
      user.entries.map((e) => '${e.key}=${e.value}').join('|');

  Map<String, dynamic> _decodeUser(String raw) {
    final map = <String, dynamic>{};
    for (final part in raw.split('|')) {
      final idx = part.indexOf('=');
      if (idx > 0) map[part.substring(0, idx)] = part.substring(idx + 1);
    }
    return map;
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}

class FakeAuthRepository implements AuthRepository {
  String? _token;

  @override
  Future<Map<String, dynamic>> login(String matricule, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (matricule == 'VAT-24-0157' && password == 'test1234') {
      _token = 'fake_token_student';
      return {
        'token': _token,
        'user': {
          'id': 2,
          'role': 'student',
          'full_name': 'Aya Koffi',
          'class': 'Terminale D',
        },
      };
    }
    if (matricule == '+22507000001' && password == 'parent1234') {
      _token = 'fake_token_parent';
      return {
        'token': _token,
        'user': {
          'id': 1,
          'role': 'parent',
          'full_name': 'Mme Koffi',
          'class': null,
        },
      };
    }
    throw DioException(
      requestOptions: RequestOptions(path: '/auth/login'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        statusCode: 401,
        data: {'error': 'Identifiants invalides'},
      ),
    );
  }

  @override
  Future<void> logout() async => _token = null;

  @override
  Future<String?> getToken() async => _token;
}
