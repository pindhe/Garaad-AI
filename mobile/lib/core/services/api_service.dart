import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

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
    try {
      final res = await http
          .get(Uri.parse('$baseUrl$path'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(res);
    } catch (e) {
      if (e is Exception && !e.toString().contains('ClientException') && !e.toString().contains('SocketException')) {
        rethrow;
      }
      throw Exception(_networkMessage(e));
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _handleResponse(res);
    } catch (e) {
      if (e is Exception && !e.toString().contains('ClientException') && !e.toString().contains('SocketException')) {
        rethrow;
      }
      throw Exception(_networkMessage(e));
    }
  }

  String _networkMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('Failed to fetch') || msg.contains('SocketException') || msg.contains('Connection refused')) {
      return 'Cannot reach server at $baseUrl. Start the backend: cd backend && npm run dev';
    }
    if (msg.contains('TimeoutException')) {
      return 'Server timed out. Check that the backend is running.';
    }
    return msg.replaceAll('Exception: ', '');
  }

  dynamic _handleResponse(http.Response res) {
    if (res.body.isEmpty) {
      if (res.statusCode >= 400) throw Exception('Request failed (${res.statusCode})');
      return {};
    }

    dynamic data;
    try {
      data = jsonDecode(res.body);
    } catch (_) {
      throw Exception('Invalid server response');
    }

    if (res.statusCode >= 400) {
      final message = data is Map ? (data['error'] ?? 'Request failed') : 'Request failed';
      throw Exception(message);
    }
    return data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await post('/auth/login', {'email': email, 'password': password});
    final token = data['token'] as String?;
    if (token == null) throw Exception('Invalid login response');
    await saveToken(token);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? gradeLevel,
  }) async {
    return Map<String, dynamic>.from(await post('/auth/register', {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'role': 'student',
      if (gradeLevel != null) 'gradeLevel': gradeLevel,
    }) as Map);
  }

  Future<List<dynamic>> getCourses() async {
    final data = await get('/courses');
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> getCourse(int id) async {
    return Map<String, dynamic>.from(await get('/courses/$id') as Map);
  }

  Future<void> enrollCourse(int id) async {
    await post('/courses/$id/enroll', {});
  }

  Future<Map<String, dynamic>> getLesson(int id) async {
    return Map<String, dynamic>.from(await get('/lessons/$id') as Map);
  }

  Future<void> completeLesson(int id) async {
    await post('/lessons/$id/complete', {});
  }

  Future<Map<String, dynamic>> chat(
    String message, {
    String? sessionId,
    List<Map<String, String>>? history,
  }) async {
    return Map<String, dynamic>.from(await post('/ai/chat', {
      'message': message,
      if (sessionId != null) 'sessionId': sessionId,
      if (history != null) 'history': history,
    }) as Map);
  }

  Future<Map<String, dynamic>> getQuiz(int id) async {
    return Map<String, dynamic>.from(await get('/exams/quizzes/$id') as Map);
  }

  Future<Map<String, dynamic>> submitQuiz(int id, List<dynamic> answers, int timeTaken) async {
    return Map<String, dynamic>.from(await post('/exams/quizzes/$id/submit', {
      'answers': answers,
      'timeTakenSeconds': timeTaken,
    }) as Map);
  }

  Future<List<dynamic>> getAssignments({int? courseId}) async {
    final path = courseId != null ? '/assignments?courseId=$courseId' : '/assignments';
    final data = await get(path);
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> getProgress() async {
    return Map<String, dynamic>.from(await get('/students/progress') as Map);
  }

  Future<List<dynamic>> getCertificates() async {
    final data = await get('/exams/certificates');
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> issueCertificate(int courseId) async {
    return Map<String, dynamic>.from(await post('/exams/certificates/$courseId', {}) as Map);
  }

  Future<List<dynamic>> getExams({int? courseId}) async {
    final path = courseId != null ? '/exams?courseId=$courseId' : '/exams';
    final data = await get(path);
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> getExam(int id) async {
    return Map<String, dynamic>.from(await get('/exams/$id') as Map);
  }

  Future<Map<String, dynamic>> submitExam(int id, List<dynamic> answers, int timeTaken) async {
    return Map<String, dynamic>.from(await post('/exams/$id/submit', {
      'answers': answers,
      'timeTakenSeconds': timeTaken,
    }) as Map);
  }

  Future<Map<String, dynamic>> submitAssignment(int id, {String? content, List<int>? fileBytes, String? fileName}) async {
    final uri = Uri.parse('$baseUrl/assignments/$id/submit');
    final request = http.MultipartRequest('POST', uri);
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    if (content != null && content.isNotEmpty) request.fields['content'] = content;
    if (fileBytes != null && fileName != null) {
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
    }
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamed);
    return Map<String, dynamic>.from(_handleResponse(res) as Map);
  }

  Future<List<dynamic>> getNotifications() async {
    final data = await get('/analytics/notifications');
    return data is List ? data : [];
  }

  Future<void> markNotificationRead(int id) async {
    await http.put(
      Uri.parse('$baseUrl/analytics/notifications/$id/read'),
      headers: _headers,
    );
  }
}
