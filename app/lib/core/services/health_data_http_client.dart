/// Health Data HTTP Client
///
/// Focused service that handles HTTP communication with Supabase Edge Function.
/// Separates HTTP concerns from batching and retry logic.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'health_data_batching_service.dart';

/// HTTP client configuration
class HttpClientConfig {
  final Duration requestTimeout;
  final bool enableCompression;
  final Map<String, String> defaultHeaders;

  const HttpClientConfig({
    this.requestTimeout = const Duration(seconds: 30),
    this.enableCompression = true,
    this.defaultHeaders = const {},
  });

  static const HttpClientConfig defaultConfig = HttpClientConfig();
}

/// Result of an HTTP upload operation
class HttpUploadResult {
  final bool isSuccess;
  final int httpStatusCode;
  final String message;
  final int samplesProcessed;
  final int samplesRejected;
  final DateTime timestamp;
  final String? errorCode;
  final Map<String, dynamic>? responseData;
  final Duration responseTime;

  const HttpUploadResult({
    required this.isSuccess,
    required this.httpStatusCode,
    required this.message,
    this.samplesProcessed = 0,
    this.samplesRejected = 0,
    required this.timestamp,
    this.errorCode,
    this.responseData,
    required this.responseTime,
  });

  factory HttpUploadResult.success({
    required int samplesProcessed,
    int samplesRejected = 0,
    String? message,
    required Duration responseTime,
    Map<String, dynamic>? responseData,
  }) {
    return HttpUploadResult(
      isSuccess: true,
      httpStatusCode: 201,
      message: message ?? 'Upload successful',
      samplesProcessed: samplesProcessed,
      samplesRejected: samplesRejected,
      timestamp: DateTime.now(),
      responseTime: responseTime,
      responseData: responseData,
    );
  }

  factory HttpUploadResult.failure({
    required int httpStatusCode,
    required String message,
    String? errorCode,
    Map<String, dynamic>? responseData,
    required Duration responseTime,
  }) {
    return HttpUploadResult(
      isSuccess: false,
      httpStatusCode: httpStatusCode,
      message: message,
      timestamp: DateTime.now(),
      errorCode: errorCode,
      responseData: responseData,
      responseTime: responseTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isSuccess': isSuccess,
      'httpStatusCode': httpStatusCode,
      'message': message,
      'samplesProcessed': samplesProcessed,
      'samplesRejected': samplesRejected,
      'timestamp': timestamp.toIso8601String(),
      'errorCode': errorCode,
      'responseData': responseData,
      'responseTimeMs': responseTime.inMilliseconds,
    };
  }
}

/// HTTP client for health data uploads
class HealthDataHttpClient {
  static final HealthDataHttpClient _instance =
      HealthDataHttpClient._internal();
  factory HealthDataHttpClient() => _instance;
  HealthDataHttpClient._internal();

  final http.Client _httpClient = http.Client();
  HttpClientConfig _config = HttpClientConfig.defaultConfig;

  /// Current configuration
  HttpClientConfig get config => _config;

  /// Update HTTP client configuration
  void updateConfig(HttpClientConfig config) {
    _config = config;
    debugPrint('🌐 HTTP client config updated');
  }

  /// Upload a batch to the Supabase Edge Function
  Future<HttpUploadResult> uploadBatch(HealthDataBatch batch) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🌐 Sending HTTP request for batch: ${batch.batchId}');

      // Prepare the request
      final url = Uri.parse(
        '${SupabaseConfig.url}/functions/v1/health-data-ingestion',
      );
      final payload = batch.toUploadPayload();

      // Get authentication token
      final authToken = await _getAuthToken();
      if (authToken == null) {
        stopwatch.stop();
        return HttpUploadResult.failure(
          httpStatusCode: 401,
          message: 'No authentication token available',
          errorCode: 'AUTH_TOKEN_MISSING',
          responseTime: stopwatch.elapsed,
        );
      }

      // Build headers
      final headers = await _buildHeaders(batch, authToken);

      // Make the HTTP request
      final response = await _httpClient
          .post(url, headers: headers, body: json.encode(payload))
          .timeout(_config.requestTimeout);

      stopwatch.stop();

      // Parse and handle response
      final result = _handleHttpResponse(
        response,
        batch.samples.length,
        stopwatch.elapsed,
      );

      debugPrint(
        '🌐 HTTP response: ${result.httpStatusCode} in ${result.responseTime.inMilliseconds}ms',
      );

      return result;
    } on TimeoutException {
      stopwatch.stop();
      return HttpUploadResult.failure(
        httpStatusCode: 408,
        message: 'Request timed out after ${_config.requestTimeout.inSeconds}s',
        errorCode: 'TIMEOUT',
        responseTime: stopwatch.elapsed,
      );
    } on SocketException catch (e) {
      stopwatch.stop();
      return HttpUploadResult.failure(
        httpStatusCode: 0,
        message: 'Network error: ${e.message}',
        errorCode: 'NETWORK_ERROR',
        responseTime: stopwatch.elapsed,
      );
    } on FormatException catch (e) {
      stopwatch.stop();
      return HttpUploadResult.failure(
        httpStatusCode: 400,
        message: 'Invalid request format: ${e.message}',
        errorCode: 'FORMAT_ERROR',
        responseTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return HttpUploadResult.failure(
        httpStatusCode: 500,
        message: 'Unexpected error: $e',
        errorCode: 'UNEXPECTED_ERROR',
        responseTime: stopwatch.elapsed,
      );
    }
  }

  /// Get authentication token from Supabase
  Future<String?> _getAuthToken() async {
    try {
      final supabaseClient = Supabase.instance.client;
      final session = supabaseClient.auth.currentSession;
      return session?.accessToken;
    } catch (e) {
      debugPrint('❌ Error getting auth token: $e');
      return null;
    }
  }

  /// Build HTTP headers for the request
  Future<Map<String, String>> _buildHeaders(
    HealthDataBatch batch,
    String authToken,
  ) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
      'X-Batch-ID': batch.batchId,
      'X-Sample-Count': batch.samples.length.toString(),
      'X-User-ID': batch.userId,
      ...config.defaultHeaders,
    };

    if (_config.enableCompression) {
      headers['Accept-Encoding'] = 'gzip';
      headers['Content-Encoding'] = 'gzip';
    }

    return headers;
  }

  /// Handle HTTP response and create result
  HttpUploadResult _handleHttpResponse(
    http.Response response,
    int totalSamples,
    Duration responseTime,
  ) {
    final statusCode = response.statusCode;
    final responseBody = response.body;

    Map<String, dynamic>? responseData;
    try {
      responseData = json.decode(responseBody) as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('⚠️ Failed to parse response JSON: $e');
      // Continue with null responseData
    }

    switch (statusCode) {
      case 200:
      case 201:
        // Success
        final processedCount =
            responseData?['samples_processed'] as int? ?? totalSamples;
        final rejectedCount = responseData?['samples_rejected'] as int? ?? 0;
        final message =
            responseData?['message'] as String? ?? 'Upload successful';

        return HttpUploadResult.success(
          samplesProcessed: processedCount,
          samplesRejected: rejectedCount,
          message: message,
          responseTime: responseTime,
          responseData: responseData,
        );

      case 400:
        // Bad request
        return HttpUploadResult.failure(
          httpStatusCode: statusCode,
          message: responseData?['error'] as String? ?? 'Bad request',
          errorCode: responseData?['error_code'] as String? ?? 'BAD_REQUEST',
          responseTime: responseTime,
          responseData: responseData,
        );

      case 401:
        // Unauthorized
        return HttpUploadResult.failure(
          httpStatusCode: statusCode,
          message: 'Authentication failed',
          errorCode: 'UNAUTHORIZED',
          responseTime: responseTime,
          responseData: responseData,
        );

      case 403:
        // Forbidden
        return HttpUploadResult.failure(
          httpStatusCode: statusCode,
          message: 'Access forbidden',
          errorCode: 'FORBIDDEN',
          responseTime: responseTime,
          responseData: responseData,
        );

      case 429:
        // Rate limited
        return HttpUploadResult.failure(
          httpStatusCode: statusCode,
          message: 'Rate limit exceeded',
          errorCode: 'RATE_LIMITED',
          responseTime: responseTime,
          responseData: responseData,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        // Server errors
        return HttpUploadResult.failure(
          httpStatusCode: statusCode,
          message: responseData?['error'] as String? ?? 'Server error',
          errorCode: 'SERVER_ERROR',
          responseTime: responseTime,
          responseData: responseData,
        );

      default:
        // Other errors
        return HttpUploadResult.failure(
          httpStatusCode: statusCode,
          message: responseData?['error'] as String? ?? 'Unknown error',
          errorCode: 'UNKNOWN_ERROR',
          responseTime: responseTime,
          responseData: responseData,
        );
    }
  }

  /// Test connectivity to the health data ingestion endpoint
  Future<bool> testConnectivity() async {
    try {
      final url = Uri.parse(
        '${SupabaseConfig.url}/functions/v1/health-data-ingestion',
      );
      final response = await _httpClient
          .head(url)
          .timeout(const Duration(seconds: 10));

      debugPrint('🌐 Connectivity test: ${response.statusCode}');
      return response.statusCode < 500;
    } catch (e) {
      debugPrint('❌ Connectivity test failed: $e');
      return false;
    }
  }

  /// Get HTTP client statistics
  Map<String, dynamic> getStats() {
    return {
      'config': {
        'requestTimeoutSeconds': _config.requestTimeout.inSeconds,
        'enableCompression': _config.enableCompression,
        'defaultHeaderCount': _config.defaultHeaders.length,
      },
      'runtime': {'clientActive': true},
    };
  }

  /// Dispose of resources
  void dispose() {
    _httpClient.close();
    debugPrint('🌐 HTTP client disposed');
  }
}
