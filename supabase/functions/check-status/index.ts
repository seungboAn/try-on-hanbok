import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';
console.log('Hello from Check Status function!');
serve(async (req)=>{
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders
    });
  }
  try {
    // Get request body or query parameters
    let taskId = null;
    if (req.method === 'GET') {
      // For GET requests, extract task_id from query parameters
      const url = new URL(req.url);
      taskId = url.searchParams.get('task_id');
    } else {
      // For POST requests, get from body
      const body = await req.json();
      taskId = body.task_id;
    }
    if (!taskId) {
      return new Response(JSON.stringify({
        error: 'task_id is required'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    // Create Supabase client
    const supabaseAdmin = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '', {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    });
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
    // Query for task in result_images table
    const { data: taskData, error: fetchError } = await supabaseAdmin.from('result_images').select('result_url, metadata, created_at, updated_at').eq('id', taskId).eq('user_id', user.id) // Ensure user can only access their own tasks
    .eq('is_active', true).single();
    if (fetchError) {
      return new Response(JSON.stringify({
        error: fetchError.message,
        task_id: taskId,
        status: 'not_found'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 404
      });
    }
    if (!taskData) {
      return new Response(JSON.stringify({
        error: 'Task not found',
        task_id: taskId,
        status: 'not_found'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 404
      });
    }
    // Extract status from metadata
    const status = taskData.metadata?.status || 'unknown';
    const errorMessage = taskData.metadata?.error_message;
    // Construct response based on status
    const response = {
      task_id: taskId,
      status: status,
      created_at: taskData.created_at,
      updated_at: taskData.updated_at
    };
    // Add image_url if result_url is available
    if (taskData.result_url) {
      response['image_url'] = taskData.result_url;
    }
    // Add error message if status is error
    if (status === 'error' && errorMessage) {
      response['error_message'] = errorMessage;
    }
    return new Response(JSON.stringify(response), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      }
    });
  } catch (error) {
    console.error('Error in check-status function:', error);
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
