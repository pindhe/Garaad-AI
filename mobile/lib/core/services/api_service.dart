import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  String? _token;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handleResponse(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  dynamic _handleResponse(http.Response res) {
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Request failed');
    }
    return data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await post('/auth/login', {'email': email, 'password': password});
    await saveToken(data['token']);
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    return await post('/auth/register', {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'role': 'student',
    });
  }

  Future<List<dynamic>> getCourses() async {
    final data = await get('/courses');
    return data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getCourse(int id) async {
    return await get('/courses/$id');
  }

  Future<void> enrollCourse(int id) async {
    await post('/courses/$id/enroll', {});
  }

  Future<Map<String, dynamic>> getLesson(int id) async {
    return await get('/lessons/$id');
  }

  Future<void> completeLesson(int id) async {
    await post('/lessons/$id/complete', {});
  }

  Future<Map<String, dynamic>> chat(String message, {String? sessionId, List<Map<String, String>>? history}) async {
    return await post('/ai/chat', {
      'message': message,
      if (sessionId != null) 'sessionId': sessionId,
      if (history != null) 'history': history,
    });
  }

  Future<Map<String, dynamic>> getQuiz(int id) async {
    return await get('/exams/quizzes/$id');
  }

  Future<Map<String, dynamic>> submitQuiz(int id, List<dynamic> answers, int timeTaken) async {
    return await post('/exams/quizzes/$id/submit', {
      'answers': answers,
      'timeTakenSeconds': timeTaken,
    });
  }

  Future<List<dynamic>> getAssignments({int? courseId}) async {
    final path = courseId != null ? '/assignments?courseId=$courseId' : '/assignments';
    final data = await get(path);
    return data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getProgress() async {
    return await get('/students/progress');
  }

  Future<List<dynamic>> getCertificates() async {
    final data = await get('/exams/certificates');
    return data as List<dynamic>;
  }
}
