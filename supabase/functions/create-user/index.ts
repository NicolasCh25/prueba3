import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
}

serve(async (req) => {
  // Handle CORS OPTIONS request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Initialize Supabase client with SERVICE_ROLE_KEY to get admin access
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      }
    })

    // 2. Authenticate the caller (using their JWT)
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'No authorization header provided' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token)
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Session invalida o expirada' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Check caller's role from profiles
    const { data: callerProfile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    if (profileError || !callerProfile) {
      return new Response(JSON.stringify({ error: 'Perfil del coordinador no encontrado' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const callerRole = callerProfile.role
    if (callerRole !== 'campaignCoordinator' && callerRole !== 'brigadeCoordinator') {
      return new Response(JSON.stringify({ error: 'No tiene permisos para crear usuarios' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 3. Parse request body
    const { cedula, nombres, apellidos, telefono, email, role } = await req.json()

    // Validate role relationship rules
    if (callerRole === 'campaignCoordinator' && role !== 'brigadeCoordinator') {
      return new Response(JSON.stringify({ error: 'El Coordinador de Campaña solo puede crear Coordinadores de Brigada' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    if (callerRole === 'brigadeCoordinator' && role !== 'vaccinator') {
      return new Response(JSON.stringify({ error: 'El Coordinador de Brigada solo puede crear Vacunadores' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 4. Create auth user with service_role privileges
    const { data: newAuthUser, error: createAuthError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password: 'Ecuador2026',
      email_confirm: true,
    })

    if (createAuthError) {
      return new Response(JSON.stringify({ error: `Error en Auth: ${createAuthError.message}` }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 5. Insert profile with the newly created user's ID
    const { data: newProfile, error: insertProfileError } = await supabaseAdmin
      .from('profiles')
      .insert({
        id: newAuthUser.user.id,
        cedula,
        nombres,
        apellidos,
        telefono,
        email,
        role,
        is_first_login: true,
      })
      .select()
      .single()

    if (insertProfileError) {
      // Rollback auth user creation if profile insert fails
      await supabaseAdmin.auth.admin.deleteUser(newAuthUser.user.id)
      return new Response(JSON.stringify({ error: `Error en Base de Datos: ${insertProfileError.message}` }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify(newProfile), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
