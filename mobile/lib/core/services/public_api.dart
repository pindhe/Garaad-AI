import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PlatformStats {
  final int totalStudents;
  final int totalCourses;
  final int activeUsers;
  final int aiSessionsToday;
  final String tagline;
  final String platform;
  final bool offline;

  const PlatformStats({
    this.totalStudents = 0,
    this.totalCourses = 0,
    this.activeUsers = 0,
    this.aiSessionsToday = 0,
    this.tagline = 'Your AI Teacher Anytime',
    this.platform = 'MacallinAI',
    this.offline = true,
  });

  factory PlatformStats.fromJson(Map<String, dynamic> json) {
    return PlatformStats(
      totalStudents: _toInt(json['totalStudents']),
      totalCourses: _toInt(json['totalCourses']),
      activeUsers: _toInt(json['activeUsers']),
      aiSessionsToday: _toInt(json['aiSessionsToday']),
      tagline: json['tagline']?.toString() ?? 'Your AI Teacher Anytime',
      platform: json['platform']?.toString() ?? 'MacallinAI',
      offline: json['offline'] == true,
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}

class PublicApi {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<PlatformStats> fetchStats() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/public/stats'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode >= 400) return const PlatformStats(offline: true);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return PlatformStats.fromJson(data);
    } catch (_) {
      return const PlatformStats(offline: true);
    }
  }

  static Future<bool> checkHealth() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
