import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

console.log('Hello from Generate Hanbok Image function!');

const GKE_ENDPOINT = `http://${Deno.env.get('GKE_URL')}/inference`;
const WEBHOOK_URL = Deno.env.get('WEBHOOK_URL') || 'https://awxineofxcvdpsxlvtxv.supabase.co/functions/v1/hanbok-webhook';

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders
    });
  }

  try {
    // Get request body
    const { sourceImageUrl, targetImageUrl } = await req.json();

    // Validate inputs
    if (!sourceImageUrl) {
      return new Response(JSON.stringify({
        error: 'Source image URL is required'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }

    if (!targetImageUrl) {
      return new Response(JSON.stringify({
        error: 'Target hanbok image URL is required'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }

    // Create Supabase client
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    );

    // Verify and get user
    const authHeader = req.headers.get('Authorization');
    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token);

    if (userError || !user) {
      return new Response(JSON.stringify({
        error: 'Unauthorized'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 401
      });
    }

    // Generate a unique task ID
    const taskId = crypto.randomUUID();

    // Extract user_id from the URL safely
    let userImageId = user.id;
    let presetId = 'preset-' + taskId;

    try {
      // For userImageId, extract the UUID from the user-images path if possible
      const userImageMatch = sourceImageUrl.match(/user-images\/([0-9a-f-]+)/i);
      if (userImageMatch) {
        userImageId = userImageMatch[1];
      }

      // For presetId, extract a meaningful identifier but don't force it to be a UUID
      if (targetImageUrl.includes('preset-images')) {
        // Get the filename without extension and query params
        const presetFilename = targetImageUrl.split('/').pop()?.split('?')[0];
        if (presetFilename) {
          // If the filename has a UUID embedded (like traditional-UUID.png), extract it
          const uuidMatch = presetFilename.match(/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/i);
          if (uuidMatch) {
            presetId = uuidMatch[1];
          } else {
            presetId = 'preset-' + presetFilename;
          }
        }
      }
    } catch (e) {
      console.error('Error parsing image URLs:', e);
      // Use defaults already set above
    }

    // Check if we already have a cached result for this source+target combination
    const { data: existingResult, error: cacheCheckError } = await supabaseAdmin
      .from('result_images')
      .select('id, result_url')
      .eq('user_id', user.id)
      .eq('metadata->source_image_url', sourceImageUrl)
      .eq('metadata->target_image_url', targetImageUrl)
      .eq('is_active', true)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (existingResult && existingResult.result_url) {
      console.log('Returning cached result for this image combination');
      return new Response(JSON.stringify({
        success: true,
        task_id: existingResult.id,
        cached: true,
        status: 'completed',
        image_url: existingResult.result_url
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      });
    }

    // Create metadata with status information
    const metadata = {
      status: 'processing',
      source_image_url: sourceImageUrl,
      target_image_url: targetImageUrl,
      error_message: null,
      gke_task_id: null
    };

    // Create the task record according to the actual table schema
    const { data: taskData, error: taskError } = await supabaseAdmin.from('result_images').insert({
      id: taskId,
      user_id: user.id,
      user_image_id: userImageId,
      preset_id: presetId,
      result_url: null,
      metadata: metadata,
      is_active: true,
      created_at: new Date().toISOString()
    }).select().single();

    if (taskError) {
      return new Response(JSON.stringify({
        error: `Failed to create task record: ${taskError.message}`
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 500
      });
    }

    // 즉시 task_id를 응답하고 백그라운드에서 GKE 요청 처리
    console.log(`Immediately returning task_id: ${taskId} and handling GKE request in background`);
    
    // 비동기 함수를 시작하고 응답을 기다리지 않음
    (async () => {
      try {
        // Send request to GKE inference endpoint
        console.log(`Sending request to GKE for task ${taskId}`);
        const gkeResponse = await fetch(GKE_ENDPOINT, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            source_path: sourceImageUrl,
            target_path: targetImageUrl,
            webhook_url: `${WEBHOOK_URL}?task_id=${taskId}`,
            task_id: taskId
          })
        });

        // Handle GKE response
        if (!gkeResponse.ok) {
          const errorText = await gkeResponse.text();
          // Update task status to error
          const updatedMetadata = {
            ...metadata,
            status: 'error',
            error_message: `GKE error: ${errorText}`
          };
          await supabaseAdmin.from('result_images').update({
            metadata: updatedMetadata,
            updated_at: new Date().toISOString()
          }).eq('id', taskId);
          console.error(`Background GKE request failed: ${errorText}`);
        } else {
          const gkeData = await gkeResponse.json();
          // If GKE returns its own task_id, use it for logging but keep our task_id for consistency
          if (gkeData.task_id) {
            console.log(`GKE returned task_id: ${gkeData.task_id}, our task_id: ${taskId}`);
            // Update our record with the GKE task_id for reference
            const updatedMetadata = {
              ...metadata,
              gke_task_id: gkeData.task_id
            };
            await supabaseAdmin.from('result_images').update({
              metadata: updatedMetadata,
              updated_at: new Date().toISOString()
            }).eq('id', taskId);
          }
        }
      } catch (error) {
        console.error(`Background GKE request processing error: ${error.message}`);
        // 백그라운드 오류 처리
        const updatedMetadata = {
          ...metadata,
          status: 'error',
          error_message: `Background processing error: ${error.message}`
        };
        await supabaseAdmin.from('result_images').update({
          metadata: updatedMetadata,
          updated_at: new Date().toISOString()
        }).eq('id', taskId);
      }
    })().catch(error => {
      console.error(`Unhandled error in background task: ${error}`);
    });

    // 즉시 task_id를 클라이언트에 반환
    return new Response(JSON.stringify({
      success: true,
      task_id: taskId,
      message: 'Hanbok image generation request has been submitted successfully',
      status: 'processing'
    }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      }
    });
  } catch (error) {
    console.error('Error in generate-hanbok-image function:', error);
    return new Response(JSON.stringify({
      error: error.message
    }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      },
      status: 500
    });
  }
}); 