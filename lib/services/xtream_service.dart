import 'package:dio/dio.dart';

/// Service for Xtream Codes IPTV authentication
/// The most common IPTV login format: server URL + username + password
class XtreamService {
  final Dio _dio;

  XtreamService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ));

  /// Normalize the server URL (ensure it has scheme, no trailing slash)
  static String normalizeUrl(String url) {
    var normalized = url.trim();
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'http://$normalized';
    }
    // Remove trailing slash
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  /// Build the M3U playlist URL from Xtream credentials
  /// Format: http://host:port/get.php?username=X&password=Y&type=m3u_plus&output=ts
  static String buildM3UUrl({
    required String serverUrl,
    required String username,
    required String password,
  }) {
    final base = normalizeUrl(serverUrl);
    return '$base/get.php?username=$username&password=$password&type=m3u_plus&output=ts';
  }

  /// Build the player API URL (used for account validation)
  static String buildApiUrl({
    required String serverUrl,
    required String username,
    required String password,
  }) {
    final base = normalizeUrl(serverUrl);
    return '$base/player_api.php?username=$username&password=$password';
  }

  /// Authenticate with the Xtream server and validate credentials
  /// Returns account info on success, throws on failure
  Future<XtreamAccount> authenticate({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final apiUrl = buildApiUrl(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );

    try {
      final response = await _dio.get(apiUrl);
      final data = response.data;

      // Parse response (can be a Map or JSON string)
      final Map<String, dynamic> json =
          data is Map ? Map<String, dynamic>.from(data) : {};

      final userInfo = json['user_info'];
      if (userInfo == null) {
        throw XtreamException('Invalid credentials or server response');
      }

      final auth = userInfo['auth'];
      if (auth == 0 || auth == '0') {
        throw XtreamException('Authentication failed. Check username/password.');
      }

      return XtreamAccount.fromJson(Map<String, dynamic>.from(userInfo));
    } on DioException catch (e) {
      throw XtreamException('Connection error: ${e.message}');
    }
  }
}

/// Xtream account information returned after login
class XtreamAccount {
  final String username;
  final String status;
  final bool isActive;
  final DateTime? expiryDate;
  final int maxConnections;
  final int activeConnections;

  XtreamAccount({
    required this.username,
    required this.status,
    required this.isActive,
    this.expiryDate,
    this.maxConnections = 1,
    this.activeConnections = 0,
  });

  factory XtreamAccount.fromJson(Map<String, dynamic> json) {
    DateTime? expiry;
    final expTimestamp = json['exp_date'];
    if (expTimestamp != null && expTimestamp.toString().isNotEmpty) {
      final seconds = int.tryParse(expTimestamp.toString());
      if (seconds != null) {
        expiry = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }

    return XtreamAccount(
      username: json['username']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Unknown',
      isActive: json['status']?.toString().toLowerCase() == 'active',
      expiryDate: expiry,
      maxConnections: int.tryParse(json['max_connections']?.toString() ?? '1') ?? 1,
      activeConnections: int.tryParse(json['active_cons']?.toString() ?? '0') ?? 0,
    );
  }

  /// Days remaining until expiry
  int? get daysRemaining {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }
}

/// Custom exception for Xtream errors
class XtreamException implements Exception {
  final String message;
  XtreamException(this.message);

  @override
  String toString() => message;
}
