import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_config.dart';
import 'dart:async'; // TimeoutException 클래스를 가져오기 위해 추가

class InferenceService {
  // Singleton pattern 
  static final InferenceService _instance = InferenceService._internal();
  factory InferenceService() => _instance;
  InferenceService._internal();
  
  // Task IDs from submitted requests
  final List<String> _taskIds = [];
  List<String> get taskIds => _taskIds;
  
  // Map of task IDs to their result URLs
  final Map<String, String> _resultUrls = {};
  Map<String, String> get resultUrls => _resultUrls;
  
  // Generate image by sending a request to the Edge Function
  Future<String?> generateHanbokFitting({
    required String sourcePath, 
    required String targetPath,
    String? webhookUrl,
  }) async {
    try {
      // Get auth token
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        throw Exception('Authentication token required for image generation');
      }
      
      // Edge function endpoint
      final String apiUrl = SupabaseConfig.generateHanbokImageEndpoint;
      
      debugPrint('Calling edge function: $apiUrl');
      debugPrint('Source Path: $sourcePath');
      debugPrint('Target Path: $targetPath');
      
      final Map<String, dynamic> requestBody = {
        'sourceImageUrl': sourcePath,
        'targetImageUrl': targetPath,
      };
      
      // Add webhook URL if provided
      if (webhookUrl != null) {
        requestBody['webhookUrl'] = webhookUrl;
      }
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // If we got a cached result, return it immediately
        if (data['cached'] == true && data['image_url'] != null) {
          debugPrint('Cached result found: ${data['image_url']}');
          return data['image_url'];
        }
        
        // Store the task ID for polling
        final String taskId = data['task_id'];
        
        // Add task ID to list, limited to 5 most recent
        _taskIds.add(taskId);
        if (_taskIds.length > 5) {
          _taskIds.removeAt(0); // Remove oldest task
        }
        
        debugPrint('Task submitted with ID: $taskId');
        
        // Return null to indicate that the client should poll for the result
        return null;
      } else {
        debugPrint('Image generation request failed: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to submit image generation request');
      }
    } catch (e) {
      debugPrint('Error during image generation request: $e');
      rethrow;
    }
  }
  
  // Check status of a task
  Future<Map<String, dynamic>> checkTaskStatus(String taskId) async {
    try {
      // Get auth token
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        debugPrint('No auth token available for status check');
        throw Exception('Authentication token required for status check');
      }
      
      // Edge function endpoint
      final String apiUrl = '${SupabaseConfig.checkStatusEndpoint}?task_id=$taskId';
      
      debugPrint('Checking status for task: $taskId');
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // If completed, store the result URL
        if (data['status'] == 'completed' && data['image_url'] != null) {
          final imageUrl = data['image_url'];          
          _resultUrls[taskId] = imageUrl;
        }
        
        return data;
      } else {
        debugPrint('Status check failed: ${response.statusCode}, ${response.body}');
        return {
          'status': 'error',
          'error': 'Failed to check task status: ${response.statusCode}',
          'error_message': response.body,
        };
      }
    } catch (e) {
      debugPrint('Error checking task status: $e');
      return {
        'status': 'error',
        'error': 'Error checking task status: $e',
        'error_message': e.toString(),
      };
    }
  }
  
  // Get result for a specific task ID if available
  String? getResultForTask(String taskId) {
    return _resultUrls[taskId];
  }
  
  // Clear task history
  void clearTasks() {
    _taskIds.clear();
    _resultUrls.clear();
  }
  
  // SSE를 사용하여 task 상태 확인 (실시간 이벤트 스트림)
  Stream<Map<String, dynamic>> checkTaskStatusWithSSE(String taskId) async* {
    debugPrint('Starting SSE connection for task: $taskId');
    
    // 클라이언트와 구독 관리를 위한 변수
    http.Client? client;
    bool hasCompletedSuccessfully = false;
    
    try {
      // Get auth token
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        debugPrint('No auth token available for SSE connection');
        throw Exception('Authentication token required for SSE connection');
      }
      
      // Edge function endpoint with token in query parameter
      final String baseUrl = SupabaseConfig.checkStatusSseEndpoint;
      final Uri uri = Uri.parse('$baseUrl?task_id=$taskId&token=$token');
      
      debugPrint('SSE request URL: ${uri.toString().split('?')[0]}?task_id=$taskId&token=REDACTED');
      
      // Create HTTP client with long timeout for SSE connection
      client = http.Client();
      final request = http.Request('GET', uri);
      
      // Set headers - Authorization header is also included for compatibility
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      request.headers['Connection'] = 'keep-alive';
      request.headers['Authorization'] = 'Bearer $token';
      
      debugPrint('Sending SSE request...');
      
      // 초기 연결 이벤트를 스트림에 전달 (연결 중임을 알림)
      yield {
        'status': 'connecting',
        'task_id': taskId,
        'message': 'Initiating SSE connection...'
      };
      
      // Send the request with timeout
      final response = await client.send(request).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('SSE connection request timed out');
          throw TimeoutException('SSE connection request timed out');
        }
      );
      
      debugPrint('SSE request sent, status code: ${response.statusCode}');
      
      // Check response status
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        debugPrint('SSE connection failed: ${response.statusCode}, $body');
        
        // Return error as a stream event and then close
        yield {
          'status': 'error',
          'error': 'SSE connection failed: ${response.statusCode}',
          'error_message': body
        };
        
        client.close();
        client = null;
        return;
      }
      
      // Process the stream of events
      await for (final chunk in response.stream.timeout(
        const Duration(minutes: 5), // 스트림 전체 타임아웃
        onTimeout: (sink) {
          debugPrint('SSE stream timed out');
          sink.close();
        }
      ).transform(utf8.decoder)) {
        // 이미 완료 상태로 처리된 경우 추가 데이터 무시
        if (hasCompletedSuccessfully) {
          debugPrint('Ignoring additional data after completion');
          continue;
        }
        
        // Parse SSE data format (data: {...}\n\n)
        debugPrint('Received SSE chunk (${chunk.length} bytes)');
        
        // Process each line in the chunk
        for (var line in chunk.split('\n')) {
          if (line.trim().isEmpty) continue;
          
          if (line.startsWith('data: ')) {
            try {
              // Extract the JSON data
              final jsonStr = line.substring(6);
              final data = jsonDecode(jsonStr);
              
              // 디버그 로깅에서 민감한 정보 제거
              Map<String, dynamic> logData = Map<String, dynamic>.from(data);
              if (logData['image_url'] != null) {
                logData['image_url'] = '[REDACTED URL]';
              }
              debugPrint('Parsed SSE data: ${data['status']}, data: $logData');
              
              // Yield the parsed data as a stream event
              yield data;
              
              // If this is a terminal state, mark as completed
              if (data['status'] == 'completed' || 
                  data['status'] == 'failed' || 
                  data['status'] == 'error') {
                debugPrint('SSE stream completed for task: $taskId with status: ${data['status']}');
                hasCompletedSuccessfully = true;
                
                // 스트림 종료를 안전하게 처리
                await Future.delayed(const Duration(milliseconds: 100));
                break;
              }
            } catch (e) {
              debugPrint('Error parsing SSE data: $e, data: $line');
              
              // 파싱 오류지만 완전히 실패로 처리하지 않음
              // 다음 이벤트가 올바르게 형식화되어 있을 수 있음
              yield {
                'status': 'warning',
                'message': 'Error parsing SSE data',
                'error_message': e.toString()
              };
            }
          } else if (line.startsWith(':')) {
            // Keep-alive comment, ignore
            debugPrint('SSE keep-alive received');
          } else {
            debugPrint('Unknown SSE line format: $line');
          }
        }
        
        // 완료 상태로 처리된 경우 스트림 종료
        if (hasCompletedSuccessfully) {
          debugPrint('Breaking SSE stream after completion');
          break;
        }
      }
      
      // Stream ended normally
      debugPrint('SSE stream ended normally for task: $taskId');
      if (client != null) {
        client.close();
        client = null;
      }
    } catch (e) {
      debugPrint('Error in SSE connection: $e');
      
      // Close the client if still open
      if (client != null) {
        client.close();
        client = null;
      }
      
      // BodyStreamBuffer was aborted 오류는 이미 성공적으로 처리된 경우가 많음
      if (hasCompletedSuccessfully && e.toString().contains('BodyStreamBuffer was aborted')) {
        debugPrint('Ignoring BodyStreamBuffer abort after successful completion');
        return;
      }
      
      // Return error as a stream event
      yield {
        'status': 'error',
        'error': 'SSE connection error',
        'error_message': e.toString()
      };
    }
  }
} 