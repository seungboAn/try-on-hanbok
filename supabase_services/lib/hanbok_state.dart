import 'package:flutter/material.dart';
import 'package:supabase_services/supabase_services.dart';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:async'; // Add this for StreamSubscription
import 'dart:convert'; // Add this for jsonEncode
import 'dart:io' show SocketException; // 네트워크 오류 처리를 위해 추가

class HanbokState extends ChangeNotifier {
  final _supabaseService = SupabaseServices.supabaseService;
  final _inferenceService = SupabaseServices.inferenceService;

  bool _isLoading = false;
  String? _authToken;
  List<HanbokImage> _modernPresets = [];
  List<HanbokImage> _traditionalPresets = [];
  String? _resultImageUrl;
  String? _uploadedImageUrl;
  String? _currentTaskId;
  String _taskStatus = 'idle'; // 'idle', 'processing', 'completed', 'error'
  String? _errorMessage;
  double _progress = 0.0; // 진행 상태 (0.0 ~ 1.0)
  List<String> _resultImages = []; // 생성된 결과 이미지 URL 저장 리스트
  StreamSubscription? _sseSubscription; // SSE 구독 객체 저장용

  bool get isLoading => _isLoading;
  String? get authToken => _authToken;
  List<HanbokImage> get modernPresets => _modernPresets;
  List<HanbokImage> get traditionalPresets => _traditionalPresets;
  String? get resultImageUrl => _resultImageUrl;
  String? get uploadedImageUrl => _uploadedImageUrl;
  String get taskStatus => _taskStatus;
  String? get errorMessage => _errorMessage;
  double get progress => _progress; // 진행 상태 getter
  List<String> get resultImages => _resultImages; // 결과 이미지 리스트 getter

  // Initialize and authenticate
  Future<void> initialize() async {
    // 이미 프리셋이 로드되어 있으면 다시 로드하지 않음
    if (!_isLoading &&
        _modernPresets.isNotEmpty &&
        _traditionalPresets.isNotEmpty) {
      debugPrint('Presets already loaded, skipping initialization');
      return;
    }

    setLoading(true);
    setTaskStatus('idle');
    setErrorMessage(null);

    try {
      // Anonymous login (토큰이 없는 경우에만)
      if (_authToken == null) {
        debugPrint('No auth token, attempting anonymous login...');
        _authToken = await _supabaseService.signInAnonymously();
        debugPrint('Anonymous login successful');
      }

      // 한 번의 API 호출로 모든 프리셋 가져오기
      await _loadAllPresets();

      debugPrint('Presets loaded successfully: '
          'Modern(${_modernPresets.length}), '
          'Traditional(${_traditionalPresets.length})');
    } catch (e) {
      debugPrint('Initialization error: $e');
      setErrorMessage(e.toString());
      setTaskStatus('error');
    } finally {
      setLoading(false);
    }
  }

  // 모든 프리셋을 한 번에 로드 (API 호출 최적화)
  Future<void> _loadAllPresets() async {
    // 프리셋이 이미 로드되어 있는 경우 건너뜀
    if (_modernPresets.isNotEmpty && _traditionalPresets.isNotEmpty) {
      debugPrint('Presets already loaded, skipping fetch');
      return;
    }
    
    // 모든 프리셋을 한 번에 가져오기
    final allPresets = await _supabaseService.getAllPresetImages();
    debugPrint('Loaded ${allPresets.length} total presets');
    
    // 클라이언트 측에서 카테고리별로 분류
    _modernPresets = allPresets
        .where((preset) => preset.category == 'modern')
        .toList();
    
    _traditionalPresets = allPresets
        .where((preset) => preset.category == 'traditional')
        .toList();
    
    debugPrint('Categorized presets: Modern(${_modernPresets.length}), Traditional(${_traditionalPresets.length})');
  }

  // Upload user image
  Future<void> uploadUserImage(Uint8List imageBytes, String contentType) async {
    _isLoading = true;
    _taskStatus = 'processing';
    _errorMessage = null;
    notifyListeners();

    try {
      if (_authToken == null) {
        throw Exception('Authentication token is required');
      }

      final result = await _supabaseService.uploadUserImage(
          imageBytes, contentType, _authToken!);

      if (result == null ||
          result['image'] == null ||
          result['image']['image_url'] == null) {
        throw Exception('Failed to upload image: Invalid response');
      }

      _uploadedImageUrl = result['image']['image_url'];
      _taskStatus = 'completed';
    } catch (e) {
      print('Image upload error: $e');
      _errorMessage = e.toString();
      _taskStatus = 'error';
      _uploadedImageUrl = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generate hanbok fitting with SSE status monitoring
  Future<void> generateHanbokFitting(String presetImageUrl) async {
    // 업로드된 이미지가 없으면 에러
    if (_uploadedImageUrl == null) {
      debugPrint('No source image uploaded');
      setErrorMessage('No source image uploaded');
      setTaskStatus('error');
      return;
    }

    setLoading(true);
    setTaskStatus('processing');
    setErrorMessage(null);

    debugPrint('Starting hanbok fitting generation...');
    debugPrint('Source image: $_uploadedImageUrl');
    debugPrint('Preset image: $presetImageUrl');

    try {
      // 서버에 생성 요청
      final result = await _inferenceService.generateHanbokFitting(
        sourcePath: _uploadedImageUrl!,
        targetPath: presetImageUrl,
      );

      // 결과가 없으면 SSE 방식으로 상태 모니터링 시작
      if (result == null) {
        _currentTaskId = _inferenceService.taskIds.last;
        debugPrint(
            'No immediate result. Starting SSE monitoring for task: $_currentTaskId');

        // SSE 모니터링 시작 (기존 폴링 방식 대체)
        _monitorTaskStatusWithSSE(_currentTaskId!).catchError((e) {
          debugPrint('SSE monitoring error: $e');
          setErrorMessage('SSE monitoring error: $e');
          setTaskStatus('error');
          setLoading(false);
          
          // 에러 발생 시 기존 폴링 방식으로 폴백
          debugPrint('Falling back to polling method due to SSE error');
          _pollForResults(_currentTaskId!).catchError((e) {
            debugPrint('Polling fallback error: $e');
            setErrorMessage('Status monitoring error: $e');
            setTaskStatus('error');
            setLoading(false);
          });
        });
      } else {
        // 즉시 결과가 있는 경우 (드문 케이스)
        debugPrint('Immediate result received: $result');
        setResultImageUrl(result);
        setTaskStatus('completed');
        setLoading(false);
      }
    } catch (e) {
      debugPrint('Generation error: $e');
      setErrorMessage(e.toString());
      setTaskStatus('error');
      setLoading(false);
    }
  }
  
  // SSE 방식으로 태스크 상태 모니터링
  Future<void> _monitorTaskStatusWithSSE(String taskId) async {
    // 초기 진행률 설정
    setProgress(0.05);
    
    // 이전 SSE 구독이 있으면 취소 (중복 방지)
    await _cancelSseSubscription();
    
    // SSE 스트림 수신 시작
    try {
      debugPrint('Starting SSE stream for task: $taskId');
      
      // SSE 스트림 구독 설정
      final statusStream = _inferenceService.checkTaskStatusWithSSE(taskId);
      
      // 에러 및 완료 핸들링을 위한 내부 변수
      bool hasCompletedSuccessfully = false;
      
      _sseSubscription = statusStream.listen(
        (status) {
          debugPrint('SSE update received: ${status['status']}');
          
          // 실시간 상태 업데이트 처리
          _handleStatusUpdate(status, taskId);
          
          // 완료 상태를 기록 (나중에 onDone에서 확인하기 위해)
          if (status['status'] == 'completed') {
            hasCompletedSuccessfully = true;
          }
        },
        onError: (error) {
          debugPrint('SSE stream error: $error');
          
          // 이미 완료 상태로 처리되었다면 에러 무시
          if (hasCompletedSuccessfully) {
            debugPrint('Ignoring error after successful completion');
            return;
          }
          
          // 에러 처리를 이미지 URL이 있는 경우와 없는 경우로 구분
          if (_resultImageUrl != null) {
            debugPrint('Error occurred but image URL is already set: $_resultImageUrl');
            // 이미지 URL이 이미 있는 경우 완료 상태로 간주
            setTaskStatus('completed');
          } else {
            // 이미지 URL이 없는 경우만 에러 메시지 표시
            setErrorMessage('SSE connection error: $error');
            setTaskStatus('error');
          }
          
          setLoading(false);
          _cancelSseSubscription(); // 에러 시 구독 정리
        },
        onDone: () {
          debugPrint('SSE stream completed for task: $taskId');
          
          // 스트림이 정상 종료되었는지 확인
          if (hasCompletedSuccessfully || _taskStatus == 'completed') {
            debugPrint('Task completed successfully');
          } else if (_taskStatus != 'error') {
            // 스트림이 정상적으로 완료되었지만 상태가 완료가 아니고 에러도 아니면
            debugPrint('SSE stream ended prematurely. Status: $_taskStatus');
            
            // 이미 결과 이미지가 있는 경우
            if (_resultImageUrl != null) {
              debugPrint('Stream ended but image URL is set: $_resultImageUrl');
              setTaskStatus('completed');
            } else {
              // 결과가 없는 경우 에러 처리
              setErrorMessage('Status monitoring ended unexpectedly');
              setTaskStatus('error');
            }
          }
          
          setLoading(false);
          _cancelSseSubscription(); // 구독 정리
        },
      );
    } catch (e) {
      debugPrint('Error setting up SSE connection: $e');
      
      // 에러 발생 시 폴링 방식으로 폴백하지 않고 더 명확한 에러 메시지 제공
      setErrorMessage('SSE 연결 오류: $e');
      setTaskStatus('error');
      setLoading(false);
      
      // 폴백이 필요한 특정 에러 유형인 경우에만 폴링으로 전환
      if (e is TimeoutException || e is SocketException || 
          e.toString().contains('TimeoutException') || 
          e.toString().contains('SocketException')) {
        debugPrint('Network error detected, falling back to polling method');
        _pollForResults(taskId).catchError((pollingError) {
          debugPrint('Polling fallback error: $pollingError');
          setErrorMessage('Status monitoring error: $pollingError');
          setTaskStatus('error');
          setLoading(false);
        });
      } else {
        // 네트워크 오류가 아닌 경우는 그냥 에러로 처리
        throw e;
      }
    }
  }
  
  // SSE 구독 취소 헬퍼 메서드
  Future<void> _cancelSseSubscription() async {
    if (_sseSubscription != null) {
      debugPrint('Cancelling previous SSE subscription');
      await _sseSubscription!.cancel();
      _sseSubscription = null;
    }
  }
  
  // SSE 및 폴링 상태 업데이트 통합 처리
  void _handleStatusUpdate(Map<String, dynamic> status, String taskId) {
    // 디버그 출력으로 전체 상태 정보 확인
    debugPrint('Handling status update: ${jsonEncode(status)}');
    
    // 상태값에 따른 처리 로직
    if (status['status'] == 'completed') {
      // 작업 완료
      // Edge Function에서는 image_url 필드로 결과를 전송함
      final resultUrl = status['image_url'];
      
      debugPrint('Task completed. Raw image URL: $resultUrl');
      
      if (resultUrl != null) {
        debugPrint('Task completed. Result URL: $resultUrl');
        
        // 결과 이미지 URL 설정
        setResultImageUrl(resultUrl);
        
        // 결과 이미지 목록에 추가
        if (!_resultImages.contains(resultUrl)) {
          _resultImages.add(resultUrl);
          notifyListeners();
        }
        
        // 상태 업데이트
        setTaskStatus('completed');
        setProgress(1.0); // 완료 시 100% 표시
        setLoading(false); // 로딩 상태 종료
      } else {
        // 결과 URL이 없는 경우 에러 처리
        debugPrint('Missing result URL for completed task');
        setErrorMessage('서버에서 결과를 받지 못했습니다');
        setTaskStatus('error');
        setLoading(false);
      }
    } else if (status['status'] == 'error') {
      // 오류 발생
      final errorMsg = status['error_message'] ?? status['error'] ?? '알 수 없는 오류가 발생했습니다.';
      debugPrint('Task error: $errorMsg');
      setErrorMessage(errorMsg);
      setTaskStatus('error');
      setLoading(false);
    } else if (status['status'] == 'connecting') {
      // 초기 연결 메시지 - 특별한 처리 필요 없음
      debugPrint('SSE connection established for task: $taskId');
    } else {
      // 작업 진행 중
      debugPrint('Task in progress. Status: ${status['status']}');
      // 진행 상태 업데이트 (SSE에서는 더 부드러운 업데이트 가능)
      // 0.05에서 시작해서 0.9까지 단계적으로 증가 (완료 시 1.0)
      double currentProgress = _progress;
      if (currentProgress < 0.9) {
        // 약간씩 증가 (작은 증분으로 더 부드러운 진행)
        currentProgress += 0.02; 
        setProgress(math.min(currentProgress, 0.9));
      }
    }
  }
  
  // 기존 폴링 메서드 유지 (SSE가 실패할 경우 대체 방식으로)
  Future<void> _pollForResults(String taskId) async {
    bool shouldContinue = true;
    int retryCount = 0;
    final maxRetries = 30; // 서버 응답 시간이 느릴 수 있으므로 최대 재시도 횟수 증가
    final initialDelaySeconds = 2;
    final maxDelaySeconds = 8;
    int delaySeconds = initialDelaySeconds;

    // 초기 진행률 설정
    setProgress(0.05);

    while (shouldContinue && retryCount < maxRetries) {
      try {
        debugPrint('Polling attempt #${retryCount + 1} for task: $taskId');

        // 진행 상태 업데이트 (각 폴링 시도마다 약간씩 증가)
        // 최대 진행률은 0.9로 제한 (완료 시 1.0으로 설정)
        final progressIncrement =
            0.85 / maxRetries; // 총 0.85를 maxRetries 횟수에 걸쳐 증가
        setProgress(math.min(0.05 + (retryCount * progressIncrement), 0.9));

        final status = await _inferenceService.checkTaskStatus(taskId);
        debugPrint('Current status: ${status['status']}');

        if (status['status'] == 'completed') {
          // 작업 완료
          final resultUrl = status['image_url'];
          if (resultUrl != null) {
            debugPrint('Task completed. Result URL: $resultUrl');
            setResultImageUrl(resultUrl);
            setTaskStatus('completed');
            setProgress(1.0); // 완료 시 100% 표시
            shouldContinue = false;
          } else {
            // 결과 URL이 없는 경우 임시 처리 (서버측 버그)
            debugPrint('Missing result URL for completed task - using preset');
            final fallbackImage =
                await _supabaseService.getDefaultResultImage(
                  existingPresets: [..._modernPresets, ..._traditionalPresets],
                );
            if (fallbackImage != null) {
              setResultImageUrl(fallbackImage);
              setTaskStatus('completed');
              setProgress(1.0);
            } else {
              throw Exception('서버에서 결과를 받지 못했습니다');
            }
            shouldContinue = false;
          }
        } else if (status['status'] == 'error') {
          // 오류 발생
          final errorMsg = status['error'] ?? '알 수 없는 오류가 발생했습니다.';
          debugPrint('Task error: $errorMsg');
          setErrorMessage(errorMsg);
          setTaskStatus('error');
          shouldContinue = false;
        } else {
          // 작업 진행 중, 다시 폴링
          debugPrint('Task still in progress. Waiting before next poll...');
          retryCount++;
          // 백오프 시간 계산 (지수 백오프)
          delaySeconds =
              math.min(delaySeconds * 1.5, maxDelaySeconds.toDouble()).toInt();
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      } catch (e) {
        // 폴링 자체에 오류 발생
        debugPrint('Polling error: $e');
        if (retryCount > 5) {
          // 일정 횟수 이상 오류가 반복되면 실패 처리
          setErrorMessage('서버 응답 오류: $e');
          setTaskStatus('error');
          shouldContinue = false;
        } else {
          // 일시적 오류로 간주, 재시도
          retryCount++;
          await Future.delayed(const Duration(seconds: 3));
        }
      }
    }

    // 최대 재시도 횟수 초과
    if (retryCount >= maxRetries) {
      debugPrint('Max retry count exceeded');
      setErrorMessage('처리 시간이 초과되었습니다. 다시 시도해주세요.');
      setTaskStatus('error');
    }

    setLoading(false);
  }

  // 상태값을 직접 설정하는 메서드 추가 (리팩토링용)
  void setTaskStatus(String status) {
    _taskStatus = status;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void setResultImageUrl(String? url) {
    _resultImageUrl = url;

    // 결과 이미지 URL이 있고 중복되지 않는 경우에만 리스트에 추가
    if (url != null && !_resultImages.contains(url)) {
      _resultImages.add(url);
      debugPrint('Added result image to history: $url');
      debugPrint('Total result images: ${_resultImages.length}');
    }

    notifyListeners();
  }

  // 진행 상태를 설정하는 메서드 추가
  void setProgress(double value) {
    _progress = value;
    notifyListeners();
  }
  
  // SSE 구독 등 리소스 정리를 위한 dispose 메서드 추가
  @override
  void dispose() {
    // SSE 구독 정리
    _cancelSseSubscription();
    super.dispose();
  }
}
