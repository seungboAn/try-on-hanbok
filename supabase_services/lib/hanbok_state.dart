import 'package:flutter/material.dart';
import 'package:supabase_services/supabase_services.dart';
import 'dart:typed_data';
import 'dart:math' as math;

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

      // Get presets by category (각 카테고리별 프리셋 로드)
      await Future.wait([
        _loadModernPresets(),
        _loadTraditionalPresets(),
      ]);

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

  // 모던 프리셋 로드
  Future<void> _loadModernPresets() async {
    if (_modernPresets.isEmpty) {
      _modernPresets =
          await _supabaseService.getPresetImages(category: 'modern');
      debugPrint('Loaded ${_modernPresets.length} modern presets');
    }
  }

  // 전통 프리셋 로드
  Future<void> _loadTraditionalPresets() async {
    if (_traditionalPresets.isEmpty) {
      _traditionalPresets =
          await _supabaseService.getPresetImages(category: 'traditional');
      debugPrint('Loaded ${_traditionalPresets.length} traditional presets');
    }
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

  // Generate hanbok fitting
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

      // 결과가 없으면 polling 시작
      if (result == null) {
        _currentTaskId = _inferenceService.taskIds.last;
        debugPrint(
            'No immediate result. Starting polling for task: $_currentTaskId');

        // 비동기로 polling 시작
        _pollForResults(_currentTaskId!).catchError((e) {
          debugPrint('Polling error: $e');
          setErrorMessage('Polling error: $e');
          setTaskStatus('error');
          setLoading(false);
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

  // Poll for results
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
                await _supabaseService.getDefaultResultImage();
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
}
