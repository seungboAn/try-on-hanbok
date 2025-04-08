// Node.js 기반 SSE 테스트 스크립트
// 실행 방법: node sse-test.js [task_id] [token]

const https = require('https');
const http = require('http');

// 명령줄 인자
const taskId = process.argv[2];
const token = process.argv[3];

if (!taskId || !token) {
  console.error('Usage: node sse-test.js [task_id] [token]');
  process.exit(1);
}

// 환경에 따라 URL 변경 (로컬 또는 프로덕션)
const isLocal = process.env.LOCAL === 'true';
let baseUrl;

if (isLocal) {
  baseUrl = 'http://localhost:54321';
} else {
  baseUrl = 'https://awxineofxcvdpsxlvtxv.supabase.co';
}

const url = `${baseUrl}/functions/v1/check-status-sse?task_id=${taskId}&token=${token}`;
console.log(`Connecting to: ${url}`);

// HTTP 클라이언트 선택 (http or https)
const client = isLocal ? http : https;

// SSE 연결 요청
const req = client.request(url, {
  method: 'GET',
  headers: {
    'Accept': 'text/event-stream',
    'Cache-Control': 'no-cache'
  }
});

req.on('response', (res) => {
  console.log(`Status code: ${res.statusCode}`);
  console.log(`Headers: ${JSON.stringify(res.headers, null, 2)}`);

  if (res.statusCode !== 200) {
    let body = '';
    res.on('data', (chunk) => {
      body += chunk;
    });
    res.on('end', () => {
      console.error(`Error response: ${body}`);
      process.exit(1);
    });
    return;
  }

  // 연결 성공, 스트림 처리
  console.log('Connected to SSE stream, waiting for events...');
  
  let buffer = '';
  
  res.on('data', (chunk) => {
    // 바이너리 데이터를 문자열로 변환
    const chunkStr = chunk.toString('utf-8');
    console.log(`Raw chunk: ${chunkStr}`);
    
    // 이전 버퍼에 새 청크 추가
    buffer += chunkStr;
    
    // 버퍼를 라인 단위로 처리
    const lines = buffer.split('\n');
    
    // 마지막 라인은 불완전할 수 있으므로 버퍼에 유지
    buffer = lines.pop();
    
    // 완전한 라인 처리
    lines.forEach(line => {
      if (line.startsWith('data: ')) {
        try {
          const jsonData = JSON.parse(line.substring(6)); // "data: " 제거
          console.log(`SSE 이벤트 수신: ${JSON.stringify(jsonData, null, 2)}`);
          
          // 종료 상태 확인
          if (['completed', 'failed', 'error'].includes(jsonData.status)) {
            console.log(`태스크가 종료 상태에 도달했습니다: ${jsonData.status}`);
            // 프로세스 종료는 하지 않고, 연결이 서버에 의해 종료되는 것을 기다림
          }
        } catch (e) {
          console.error(`JSON 파싱 오류: ${e.message}, 원본 데이터: ${line}`);
        }
      } else if (line.trim() && !line.startsWith(':')) {
        // 빈 라인이나 주석(:로 시작)이 아닌 경우
        console.log(`알 수 없는 SSE 데이터 형식: ${line}`);
      }
    });
  });
  
  res.on('end', () => {
    console.log('SSE 연결이 종료되었습니다.');
    process.exit(0);
  });
});

req.on('error', (err) => {
  console.error(`요청 오류: ${err.message}`);
  process.exit(1);
});

// 요청 전송
req.end();

// 사용자 종료 처리
process.on('SIGINT', () => {
  console.log('사용자가 연결을 종료했습니다');
  process.exit(0);
});

console.log('SSE 연결을 시도합니다...'); 