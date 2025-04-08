// SSE 테스트용 Flutter 앱 스니펫
// 기존 앱에 해당 화면을 추가하고 네비게이션으로 연결하면 됨

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_services/supabase_services.dart';
import 'dart:async';

class SseTestScreen extends StatefulWidget {
  const SseTestScreen({Key? key}) : super(key: key);

  @override
  State<SseTestScreen> createState() => _SseTestScreenState();
}

class _SseTestScreenState extends State<SseTestScreen> {
  final _taskIdController = TextEditingController();
  final _inferenceService = SupabaseServices.inferenceService;
  
  List<String> _logs = [];
  StreamSubscription? _sseSubscription;
  String _connectionStatus = 'Disconnected';
  bool _isConnected = false;
  
  @override
  void dispose() {
    _taskIdController.dispose();
    _sseSubscription?.cancel();
    super.dispose();
  }
  
  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 23)}: $message');
      // 로그가 너무 많아지지 않도록 제한
      if (_logs.length > 100) {
        _logs.removeAt(0);
      }
    });
  }
  
  void _connectToSSE() async {
    final taskId = _taskIdController.text.trim();
    if (taskId.isEmpty) {
      _addLog('Error: Task ID is required');
      return;
    }
    
    // 기존 연결 종료
    await _sseSubscription?.cancel();
    
    setState(() {
      _connectionStatus = 'Connecting...';
      _isConnected = false;
      _logs.clear();
    });
    
    _addLog('Starting SSE connection for task ID: $taskId');
    
    try {
      final statusStream = _inferenceService.checkTaskStatusWithSSE(taskId);
      
      _sseSubscription = statusStream.listen(
        (status) {
          final statusStr = status.toString();
          _addLog('Received status: $statusStr');
          
          // 상태가 완료되면 연결 종료
          if (['completed', 'failed', 'error'].contains(status['status'])) {
            _addLog('Task reached terminal state: ${status['status']}');
            
            setState(() {
              _connectionStatus = 'Disconnected (Task ${status['status']})';
              _isConnected = false;
            });
            
            _sseSubscription?.cancel();
            _sseSubscription = null;
          }
        },
        onError: (error) {
          _addLog('Error: $error');
          setState(() {
            _connectionStatus = 'Error: ${error.toString().substring(0, 50)}...';
            _isConnected = false;
          });
        },
        onDone: () {
          _addLog('SSE connection closed');
          setState(() {
            _connectionStatus = 'Disconnected';
            _isConnected = false;
          });
        },
      );
      
      setState(() {
        _connectionStatus = 'Connected';
        _isConnected = true;
      });
    } catch (e) {
      _addLog('Failed to connect: $e');
      setState(() {
        _connectionStatus = 'Connection failed';
        _isConnected = false;
      });
    }
  }
  
  void _disconnectFromSSE() async {
    _addLog('Disconnecting from SSE...');
    await _sseSubscription?.cancel();
    _sseSubscription = null;
    
    setState(() {
      _connectionStatus = 'Disconnected';
      _isConnected = false;
    });
  }
  
  void _getTaskIds() async {
    _addLog('Getting recent task IDs...');
    final taskIds = _inferenceService.taskIds;
    
    if (taskIds.isEmpty) {
      _addLog('No task IDs found');
    } else {
      _addLog('Recent task IDs:');
      for (final id in taskIds) {
        _addLog('- $id');
      }
      
      // 자동으로 가장 최근 taskId 입력란에 채우기
      _taskIdController.text = taskIds.last;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SSE 테스트'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상태 표시
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                _connectionStatus,
                style: TextStyle(
                  color: _isConnected ? Colors.green.shade800 : Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Task ID 입력 필드
            TextField(
              controller: _taskIdController,
              decoration: const InputDecoration(
                labelText: 'Task ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            
            // 버튼들
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _getTaskIds,
                    child: const Text('Get Task IDs'),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConnected ? null : _connectToSSE,
                    child: const Text('Connect'),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConnected ? _disconnectFromSSE : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Disconnect'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            
            // 로그 뷰
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _logs[index],
                      style: TextStyle(
                        color: _logs[index].contains('Error') 
                            ? Colors.red 
                            : _logs[index].contains('Received') 
                                ? Colors.blue 
                                : null,
                        fontSize: 12.0,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 