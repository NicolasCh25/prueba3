-- ==========================================
-- CONFIGURACIÓN DE BASE DE DATOS EN SUPABASE
-- ==========================================
-- Copia y ejecuta este script en el editor SQL de tu panel de Supabase.

-- Habilitar extensión pgcrypto para cifrado de contraseñas (suele estar activa)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Tabla de Perfiles (public.profiles)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cedula TEXT NOT NULL UNIQUE,
    nombres TEXT NOT NULL,
    apellidos TEXT NOT NULL,
    telefono TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL CHECK (role IN ('campaignCoordinator', 'brigadeCoordinator', 'vaccinator')),
    is_first_login BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Habilitar RLS (Row Level Security) para mayor seguridad
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Crear políticas básicas para permitir lectura y escritura pública en demo (o ajustarlas según convenga)
CREATE POLICY "Permitir acceso total a perfiles autenticados" 
ON public.profiles FOR ALL 
USING (true) 
WITH CHECK (true);


-- 2. Tabla de Sectores (public.sectors)
CREATE TABLE IF NOT EXISTS public.sectors (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    nombre TEXT NOT NULL UNIQUE,
    coordinador_brigada_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    vaccinator_ids TEXT[] NOT NULL DEFAULT '{}'::text[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.sectors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Permitir acceso total a sectores" 
ON public.sectors FOR ALL 
USING (true) 
WITH CHECK (true);


-- 3. Tabla de Vacunaciones (public.vaccinations)
CREATE TABLE IF NOT EXISTS public.vaccinations (
    id TEXT PRIMARY KEY,
    owner_name TEXT NOT NULL,
    owner_cedula TEXT NOT NULL,
    owner_phone TEXT NOT NULL,
    pet_type TEXT NOT NULL CHECK (pet_type IN ('dog', 'cat')),
    pet_name TEXT NOT NULL,
    pet_age DOUBLE PRECISION NOT NULL,
    pet_sex TEXT NOT NULL,
    vaccine_name TEXT NOT NULL,
    observations TEXT,
    image_url TEXT NOT NULL,
    local_image_path TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    sector_id TEXT REFERENCES public.sectors(id) ON DELETE CASCADE,
    is_synced BOOLEAN NOT NULL DEFAULT true
);

ALTER TABLE public.vaccinations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Permitir acceso total a vacunaciones" 
ON public.vaccinations FOR ALL 
USING (true) 
WITH CHECK (true);


-- ========================================================
-- TRIGGER PARA CREAR USUARIO EN AUTH.USERS AL INSERTAR PROFILE
-- ========================================================
-- Este trigger permite que cuando el coordinador crea un perfil desde la app, 
-- se cree automáticamente una cuenta en auth.users con la contraseña "Ecuador2026".

CREATE OR REPLACE FUNCTION public.handle_create_auth_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Verificar si el usuario ya existe en auth.users
    IF NEW.id IS NOT NULL AND EXISTS (SELECT 1 FROM auth.users WHERE id = NEW.id) THEN
        RETURN NEW;
    END IF;

    -- Asegurar que el perfil tenga un ID antes de insertar en auth.users
    IF NEW.id IS NULL THEN
        NEW.id := gen_random_uuid();
    END IF;

    INSERT INTO auth.users (
        id, 
        email, 
        encrypted_password, 
        email_confirmed_at, 
        raw_app_meta_data, 
        raw_user_meta_data, 
        aud, 
        role
    )
    VALUES (
        NEW.id,
        LOWER(NEW.email),
        crypt('Ecuador2026', gen_salt('bf', 10)),
        now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{}'::jsonb,
        'authenticated',
        'authenticated'
    );
    
    INSERT INTO auth.identities (
        id,
        user_id,
        identity_data,
        provider,
        provider_id,
        last_sign_in_at,
        created_at,
        updated_at
    )
    VALUES (
        NEW.id,
        NEW.id,
        json_build_object('sub', NEW.id::text, 'email', LOWER(NEW.email))::jsonb,
        'email',
        LOWER(NEW.email),
        now(),
        now(),
        now()
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Eliminar trigger viejo si existe
DROP TRIGGER IF EXISTS trigger_create_auth_user ON public.profiles;

-- Crear trigger que se ejecuta antes de insertar
CREATE TRIGGER trigger_create_auth_user
BEFORE INSERT ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.handle_create_auth_user();


-- ==========================================
-- INSERTAR USUARIOS DE PRUEBA INICIALES
-- ==========================================
-- Insertar las cuentas iniciales en auth.users, auth.identities y public.profiles.

-- Cuentas de Auth (Contraseña: Ecuador2026)
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
VALUES 
  ('00000000-0000-0000-0000-000000000001', 'nicolas.chiguano@epn.edu.ec', crypt('Ecuador2026', gen_salt('bf', 10)), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000002', 'edison.escobar01@epn.edu.ec', crypt('Ecuador2026', gen_salt('bf', 10)), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000003', 'vacunador@ecuador.com', crypt('Ecuador2026', gen_salt('bf', 10)), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, 'authenticated', 'authenticated');

-- Cuentas de Identities
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
VALUES
  ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', json_build_object('sub', '00000000-0000-0000-0000-000000000001', 'email', 'nicolas.chiguano@epn.edu.ec')::jsonb, 'email', '00000000-0000-0000-0000-000000000001', now(), now(), now()),
  ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', json_build_object('sub', '00000000-0000-0000-0000-000000000002', 'email', 'edison.escobar01@epn.edu.ec')::jsonb, 'email', '00000000-0000-0000-0000-000000000002', now(), now(), now()),
  ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003', json_build_object('sub', '00000000-0000-0000-0000-000000000003', 'email', 'vacunador@ecuador.com')::jsonb, 'email', '00000000-0000-0000-0000-000000000003', now(), now(), now());

-- Perfiles correspondientes
INSERT INTO public.profiles (id, cedula, nombres, apellidos, telefono, email, role, is_first_login)
VALUES
  ('00000000-0000-0000-0000-000000000001', '1723456789', 'María', 'Espinoza', '0998765432', 'nicolas.chiguano@epn.edu.ec', 'campaignCoordinator', true),
  ('00000000-0000-0000-0000-000000000002', '1787654321', 'Juan', 'Pérez', '0987654321', 'edison.escobar01@epn.edu.ec', 'brigadeCoordinator', true),
  ('00000000-0000-0000-0000-000000000003', '1799999999', 'Carlos', 'Gómez', '0977777777', 'vacunador@ecuador.com', 'vaccinator', true);


-- ==========================================
-- INSERTAR SECTORES DE PRUEBA INICIALES
-- ==========================================
INSERT INTO public.sectors (id, nombre, coordinador_brigada_id)
VALUES
  ('sec-1', 'Sauces (Guayaquil)', '00000000-0000-0000-0000-000000000002'),
  ('sec-2', 'La Mariscal (Quito)', '00000000-0000-0000-0000-000000000002'),
  ('sec-3', 'Centro Histórico (Quito)', null),
  ('sec-4', 'Urdesa (Guayaquil)', null),
  ('sec-5', 'Carapungo (Quito)', null);


-- ========================================================
-- CONFIGURACIÓN DE ALMACENAMIENTO (STORAGE BUCKET)
-- ========================================================
-- Asegúrate de crear un bucket público en Supabase llamado 'pet-images'.
-- También puedes ejecutar la siguiente consulta para insertar el bucket en la tabla de almacenamiento:
INSERT INTO storage.buckets (id, name, public) 
VALUES ('pet-images', 'pet-images', true)
ON CONFLICT (id) DO NOTHING;
