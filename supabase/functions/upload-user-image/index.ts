import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

console.log('Hello from Upload User Image function!');

// 최대 업로드 타임아웃 설정 (30초)
const UPLOAD_TIMEOUT_MS = 30000;

// Base64 데이터를 안전하게 처리하는 함수
function safeBase64Decode(base64String: string): Uint8Array {
  try {
    // base64, 문자열에서 "data:image/jpeg;base64," 같은 프리픽스 제거
    const base64Data = base64String.includes('base64,') 
      ? base64String.split('base64,')[1] 
      : base64String;
    
    if (!base64Data || base64Data.trim() === '') {
      throw new Error('Empty base64 data');
    }
    
    // base64 디코딩 및 Uint8Array로 변환
    return Uint8Array.from(atob(base64Data), c => c.charCodeAt(0));
  } catch (error) {
    console.error('Base64 decoding error:', error);
    throw new Error(`Failed to decode base64 data: ${error.message}`);
  }
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 요청 바디 추출 및 유효성 검사
    let body;
    try {
      body = await req.json();
    } catch (jsonError) {
      console.error('JSON parsing error:', jsonError);
      return new Response(JSON.stringify({
        error: 'Invalid JSON in request body'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }

    const { file } = body;
    
    if (!file || !file.base64) {
      return new Response(JSON.stringify({
        error: 'Base64 image data is required'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }

    // Create Supabase client with explicit options
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '', 
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        },
        global: {
          // 타임아웃 설정
          fetch: (url, options) => {
            return fetch(url, { 
              ...options,
              signal: AbortSignal.timeout(UPLOAD_TIMEOUT_MS) 
            });
          }
        }
      }
    );

    // 사용자 인증 확인
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({
        error: 'Authorization header is required'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 401
      });
    }
    
    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token);
    
    if (userError || !user) {
      console.error('Authentication error:', userError);
      return new Response(JSON.stringify({
        error: 'Unauthorized: ' + (userError ? userError.message : 'User not found')
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 401
      });
    }

    // Decode base64 and prepare for upload
    const contentType = file.contentType || 'image/jpeg';
    const extension = contentType.split('/')[1] || 'jpg';
    const fileName = `${user.id}/${crypto.randomUUID()}.${extension}`;
    
    let decodedData;
    try {
      decodedData = safeBase64Decode(file.base64);
      console.log(`Decoded base64 data: ${decodedData.length} bytes`);
    } catch (decodeError) {
      console.error('Base64 decoding failed:', decodeError);
      return new Response(JSON.stringify({
        error: decodeError.message
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }

    // 실제 파일 크기 검사 (5MB 제한)
    if (decodedData.length > 5 * 1024 * 1024) {
      return new Response(JSON.stringify({
        error: 'Image file is too large. Maximum size is 5MB.'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }

    console.log(`Uploading file: ${fileName}, size: ${decodedData.length} bytes`);
    
    // Upload to storage bucket with timeout
    let uploadResult;
    try {
      const uploadPromise = supabaseAdmin.storage.from('user-images').upload(
        fileName,
        decodedData,
        {
          contentType,
          upsert: true
        }
      );
      
      uploadResult = await uploadPromise;
    } catch (uploadError) {
      console.error('File upload error:', uploadError);
      return new Response(JSON.stringify({
        error: `Failed to upload file: ${uploadError.message}`
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 500
      });
    }
    
    const { data: uploadData, error: uploadError } = uploadResult;
    
    if (uploadError) {
      console.error('Storage upload error:', uploadError);
      return new Response(JSON.stringify({
        error: uploadError.message
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 500
      });
    }

    // 만료 기간이 1일(86400초)인 Presigned URL 생성
    const expiresIn = 86400; // 1일(초 단위)
    
    const { data: signedUrlData, error: signedUrlError } = await supabaseAdmin.storage
      .from('user-images')
      .createSignedUrl(fileName, expiresIn);
    
    if (signedUrlError) {
      console.error('Signed URL creation error:', signedUrlError);
      return new Response(JSON.stringify({
        error: `Failed to create signed URL: ${signedUrlError.message}`
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 500
      });
    }

    // 일반 Public URL도 백업용으로 가져오기 (만료된 URL 대체용)
    const { data: publicUrlData } = await supabaseAdmin.storage
      .from('user-images')
      .getPublicUrl(fileName);

    return new Response(JSON.stringify({
      success: true,
      image: {
        image_url: signedUrlData.signedUrl,
        public_url: publicUrlData.publicUrl,
        user_id: user.id,
        file_path: fileName,
        created_at: new Date().toISOString(),
        expires_at: new Date(Date.now() + expiresIn * 1000).toISOString()
      }
    }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      }
    });
  } catch (error) {
    console.error('Unhandled error in upload-user-image function:', error);
    
    // 에러 응답을 위한 도우미 함수
    const errorMessage = error instanceof Error 
      ? error.message 
      : 'Unknown error occurred';
    
    const errorStack = error instanceof Error && error.stack 
      ? error.stack 
      : 'No stack trace available';
    
    console.error('Error details:', errorMessage, errorStack);
    
    return new Response(JSON.stringify({
      error: errorMessage,
      type: error instanceof Error ? error.name : 'UnknownError'
    }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      },
      status: 500
    });
  }
}); 