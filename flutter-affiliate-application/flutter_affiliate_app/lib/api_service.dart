import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://87.106.214.100:8080';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Generic POST method
  static Future<Map<String, dynamic>> postData(String endpoint, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['error'] ?? data['message'] ?? 'Request failed'};
    }
  }

  // Generic GET method returning a standardized Map
  static Future<Map<String, dynamic>> getData(String endpoint) async {
    final headers = await _authHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    
    try {
      final response = await http.get(url, headers: headers);
      
      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else if (decoded is List) {
          data = {'items': decoded};
        }
      } catch (_) {
        data = {'raw': response.body};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false, 
          'error': data['error'] ?? data['message'] ?? 'Request failed with status: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Authentication: Login / Register
  static Future<Map<String, dynamic>> authenticate({
    required String email,
    required String password,
    String? name,
    String? role,
    required bool isLogin,
  }) async {
    final endpoint = isLogin ? '/api/auth/login' : '/api/auth/register';
    final body = isLogin
        ? {'email': email, 'password': password}
        : {'name': name, 'email': email, 'password': password, 'role': role};

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (isLogin && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user', jsonEncode(data['user']));
      }
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Request failed'};
    }
  }

  // Fetch Campaigns (Matches campaigns.py router -> GET /api/campaigns/)
  static Future<List<dynamic>> getCampaigns() async {
    final headers = await _authHeaders();
    final url = Uri.parse('$baseUrl/api/campaigns/');
    print('API_DEBUG: GET Request -> $url');

    final response = await http.get(url, headers: headers);
    print('API_DEBUG: GET Response [Campaigns] Status: ${response.statusCode}');
    print('API_DEBUG: Body: ${response.body}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      if (decoded is Map && decoded['campaigns'] is List) return decoded['campaigns'];
      if (decoded is Map && decoded['items'] is List) return decoded['items'];
      return [];
    }
    throw Exception('Failed to load campaigns');
  }

  // Fetch Marketplace Products (Matches marketplace.py router -> GET /api/marketplace/)
  static Future<List<dynamic>> getMarketplaceProducts() async {
    final headers = await _authHeaders();
    final url = Uri.parse('$baseUrl/api/marketplace/');
    print('API_DEBUG: GET Request -> $url');

    final response = await http.get(url, headers: headers);
    print('API_DEBUG: GET Response [Marketplace] Status: ${response.statusCode}');
    print('API_DEBUG: Body: ${response.body}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      if (decoded is Map && decoded['products'] is List) return decoded['products'];
      if (decoded is Map && decoded['items'] is List) return decoded['items'];
      return [];
    }
    throw Exception('Failed to load marketplace items');
  }

  // Fetch Creator Proof Logs (Matches submissions.py router -> GET /api/submissions/my-logs)
  static Future<List<dynamic>> getCreatorProofLogs() async {
    final headers = await _authHeaders();
    final url = Uri.parse('$baseUrl/api/submissions/my-logs');
    print('API_DEBUG: GET Request -> $url');

    final response = await http.get(url, headers: headers);
    print('API_DEBUG: GET Response [Proof Logs] Status: ${response.statusCode}');
    print('API_DEBUG: Body: ${response.body}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      if (decoded is Map && decoded['proof_logs'] is List) return decoded['proof_logs'];
      if (decoded is Map && decoded['items'] is List) return decoded['items'];
      return [];
    }
    throw Exception('Failed to load proof logs');
  }

  // Fetch Stats Overview (Matches stats router -> GET /api/stats/overview)
  static Future<Map<String, dynamic>> getStatsOverview(int creatorId) async {
    final headers = await _authHeaders();
    final url = Uri.parse('$baseUrl/api/stats/overview');
    print('API_DEBUG: GET Request -> $url');

    final response = await http.get(url, headers: headers);
    print('API_DEBUG: GET Response [Stats Overview] Status: ${response.statusCode}');
    print('API_DEBUG: Body: ${response.body}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    }
    throw Exception('Failed to load stats overview');
  }
}