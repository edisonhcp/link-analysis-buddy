
-- ============================================
-- ENUMS
-- ============================================
CREATE TYPE public.tipo_comision_empresa AS ENUM ('PORCENTAJE', 'FIJO', 'MIXTO');
CREATE TYPE public.app_role AS ENUM ('GERENCIA', 'CONDUCTOR', 'PROPIETARIO');
CREATE TYPE public.estado AS ENUM ('HABILITADO', 'INHABILITADO');
CREATE TYPE public.invitacion_rol AS ENUM ('CONDUCTOR', 'PROPIETARIO');
CREATE TYPE public.estado_asignacion AS ENUM ('ACTIVA', 'CERRADA');
CREATE TYPE public.estado_disponibilidad AS ENUM ('DISPONIBLE', 'EN_RUTA');
CREATE TYPE public.estado_viaje AS ENUM ('BORRADOR', 'CERRADO');
CREATE TYPE public.estado_semana AS ENUM ('ABIERTA', 'CERRADA');
CREATE TYPE public.accion_audit AS ENUM (
  'CONDUCTOR_DIA_FINALIZADO', 'CONDUCTOR_DIA_REABIERTO',
  'GERENCIA_DIA_FINALIZADO', 'GERENCIA_DIA_REABIERTO',
  'CONDUCTOR_SEMANA_FINALIZADA', 'CONDUCTOR_SEMANA_REABIERTA',
  'GERENCIA_SEMANA_FINALIZADA', 'GERENCIA_SEMANA_REABIERTA',
  'PROPIETARIO_SEMANA_CERRADA', 'PROPIETARIO_SEMANA_REABIERTA',
  'CONDUCTOR_VEHICULO_EN_RUTA', 'INGRESOS_EDITADOS', 'EGRESOS_EDITADOS',
  'CONDUCTOR_VEHICULO_DISPONIBLE', 'CONDUCTOR_VEHICULO_NO_DISPONIBLE'
);

-- ============================================
-- TABLES
-- ============================================

-- 1. Empresa (tenant root)
CREATE TABLE public.empresas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  ruc TEXT UNIQUE NOT NULL,
  ciudad TEXT NOT NULL,
  direccion TEXT NOT NULL,
  celular TEXT NOT NULL,
  email TEXT NOT NULL,
  logo_url TEXT,
  propietario_nombre TEXT NOT NULL,
  tipo_comision public.tipo_comision_empresa NOT NULL DEFAULT 'PORCENTAJE',
  comision_pct DOUBLE PRECISION NOT NULL DEFAULT 0.10,
  comision_fija DOUBLE PRECISION NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Profiles (linked to auth.users)
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  email TEXT NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT true,
  conductor_id UUID,
  propietario_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. User roles (separate table for security)
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  UNIQUE(user_id, role)
);

-- 4. Invitaciones
CREATE TABLE public.invitaciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  rol public.invitacion_rol NOT NULL,
  token TEXT UNIQUE NOT NULL,
  usada BOOLEAN NOT NULL DEFAULT false,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. Conductores
CREATE TABLE public.conductores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  codigo TEXT NOT NULL,
  estado public.estado NOT NULL DEFAULT 'HABILITADO',
  nombres TEXT NOT NULL,
  nacionalidad TEXT NOT NULL,
  identificacion TEXT NOT NULL,
  fecha_nacimiento DATE NOT NULL,
  estado_civil TEXT NOT NULL,
  tipo_licencia TEXT NOT NULL,
  fecha_caducidad_licencia DATE NOT NULL,
  domicilio TEXT NOT NULL,
  celular TEXT NOT NULL,
  email TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(empresa_id, codigo),
  UNIQUE(empresa_id, identificacion),
  UNIQUE(empresa_id, email)
);

-- 6. Propietarios
CREATE TABLE public.propietarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  codigo TEXT NOT NULL,
  estado public.estado NOT NULL DEFAULT 'HABILITADO',
  nombres TEXT NOT NULL,
  nacionalidad TEXT NOT NULL,
  identificacion TEXT NOT NULL,
  fecha_nacimiento DATE NOT NULL,
  estado_civil TEXT NOT NULL,
  direccion TEXT NOT NULL,
  celular TEXT NOT NULL,
  email TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(empresa_id, codigo),
  UNIQUE(empresa_id, identificacion),
  UNIQUE(empresa_id, email)
);

-- Update profiles FK for conductor/propietario
ALTER TABLE public.profiles
  ADD CONSTRAINT fk_profiles_conductor FOREIGN KEY (conductor_id) REFERENCES public.conductores(id),
  ADD CONSTRAINT fk_profiles_propietario FOREIGN KEY (propietario_id) REFERENCES public.propietarios(id);

-- 7. Vehiculos
CREATE TABLE public.vehiculos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  propietario_id UUID NOT NULL REFERENCES public.propietarios(id),
  placa TEXT NOT NULL,
  marca TEXT NOT NULL,
  modelo TEXT NOT NULL,
  anio INT,
  color TEXT NOT NULL,
  capacidad INT NOT NULL,
  tipo TEXT NOT NULL DEFAULT 'SUV',
  gps BOOLEAN NOT NULL DEFAULT false,
  seguro BOOLEAN NOT NULL DEFAULT false,
  estado public.estado NOT NULL DEFAULT 'HABILITADO',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(empresa_id, placa)
);

-- 8. Asignaciones
CREATE TABLE public.asignaciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  vehiculo_id UUID NOT NULL REFERENCES public.vehiculos(id),
  conductor_id UUID NOT NULL REFERENCES public.conductores(id),
  fecha_inicio TIMESTAMPTZ NOT NULL DEFAULT now(),
  fecha_fin TIMESTAMPTZ,
  estado public.estado_asignacion NOT NULL DEFAULT 'ACTIVA',
  disponibilidad public.estado_disponibilidad NOT NULL DEFAULT 'DISPONIBLE',
  disponible_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_asignaciones_empresa ON public.asignaciones(empresa_id);
CREATE INDEX idx_asignaciones_vehiculo ON public.asignaciones(vehiculo_id);
CREATE INDEX idx_asignaciones_conductor ON public.asignaciones(conductor_id);

-- 9. Semanas
CREATE TABLE public.semanas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  propietario_id UUID NOT NULL REFERENCES public.propietarios(id),
  vehiculo_id UUID NOT NULL REFERENCES public.vehiculos(id),
  fecha_inicio TIMESTAMPTZ NOT NULL,
  fecha_fin TIMESTAMPTZ NOT NULL,
  estado public.estado_semana NOT NULL DEFAULT 'ABIERTA',
  conductor_semana_finalizada_at TIMESTAMPTZ,
  conductor_semana_finalizada_by TEXT,
  gerencia_semana_finalizada_at TIMESTAMPTZ,
  gerencia_semana_finalizada_by TEXT,
  propietario_semana_cerrada_at TIMESTAMPTZ,
  propietario_semana_cerrada_by TEXT,
  reabierta_at TIMESTAMPTZ,
  reabierta_by TEXT,
  reabierta_by_user_id TEXT,
  motivo_reapertura TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(empresa_id, vehiculo_id, fecha_inicio)
);
CREATE INDEX idx_semanas_empresa ON public.semanas(empresa_id);
CREATE INDEX idx_semanas_propietario ON public.semanas(propietario_id);
CREATE INDEX idx_semanas_vehiculo ON public.semanas(vehiculo_id);

-- 10. Dias de operacion
CREATE TABLE public.dias_operacion (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  semana_id UUID NOT NULL REFERENCES public.semanas(id),
  fecha DATE NOT NULL,
  conductor_dia_finalizado_at TIMESTAMPTZ,
  gerencia_dia_finalizado_at TIMESTAMPTZ,
  observacion TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(semana_id, fecha)
);
CREATE INDEX idx_dias_operacion_empresa ON public.dias_operacion(empresa_id);
CREATE INDEX idx_dias_operacion_semana ON public.dias_operacion(semana_id);

-- 11. Viajes
CREATE TABLE public.viajes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  asignacion_id UUID REFERENCES public.asignaciones(id),
  semana_id UUID REFERENCES public.semanas(id),
  dia_operacion_id UUID REFERENCES public.dias_operacion(id),
  origen TEXT NOT NULL,
  destino TEXT NOT NULL,
  fecha_salida TIMESTAMPTZ NOT NULL,
  fecha_llegada TIMESTAMPTZ,
  estado public.estado_viaje NOT NULL DEFAULT 'BORRADOR',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_viajes_empresa ON public.viajes(empresa_id);
CREATE INDEX idx_viajes_semana ON public.viajes(semana_id);
CREATE INDEX idx_viajes_dia ON public.viajes(dia_operacion_id);

-- 12. Ingresos de viaje
CREATE TABLE public.ingresos_viaje (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  viaje_id UUID UNIQUE NOT NULL REFERENCES public.viajes(id),
  pasajeros_monto DECIMAL(10,2) NOT NULL DEFAULT 0,
  encomiendas_monto DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_ingreso DECIMAL(10,2) NOT NULL DEFAULT 0,
  comision_gerencia DECIMAL(10,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_ingresos_empresa ON public.ingresos_viaje(empresa_id);

-- 13. Egresos de viaje
CREATE TABLE public.egresos_viaje (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  viaje_id UUID UNIQUE NOT NULL REFERENCES public.viajes(id),
  alimentacion DECIMAL(10,2) NOT NULL DEFAULT 0,
  peaje DECIMAL(10,2) NOT NULL DEFAULT 0,
  hotel DECIMAL(10,2) NOT NULL DEFAULT 0,
  aceite DECIMAL(10,2) NOT NULL DEFAULT 0,
  pago_conductor DECIMAL(10,2) NOT NULL DEFAULT 0,
  combustible DECIMAL(10,2) NOT NULL DEFAULT 0,
  varios DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_egreso DECIMAL(10,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_egresos_empresa ON public.egresos_viaje(empresa_id);

-- 14. Audit log
CREATE TABLE public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  user_id TEXT,
  rol TEXT,
  accion public.accion_audit NOT NULL,
  viaje_id TEXT,
  semana_id TEXT,
  dia_operacion_id TEXT,
  vehiculo_id TEXT,
  antes JSONB,
  despues JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_audit_empresa ON public.audit_logs(empresa_id);
CREATE INDEX idx_audit_viaje ON public.audit_logs(viaje_id);
CREATE INDEX idx_audit_semana ON public.audit_logs(semana_id);
CREATE INDEX idx_audit_dia ON public.audit_logs(dia_operacion_id);
CREATE INDEX idx_audit_vehiculo ON public.audit_logs(vehiculo_id);

-- 15. Vehiculo disponibilidad
CREATE TABLE public.vehiculo_disponibilidad (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  vehiculo_id UUID UNIQUE NOT NULL REFERENCES public.vehiculos(id),
  disponible public.estado_disponibilidad NOT NULL DEFAULT 'DISPONIBLE',
  marcado_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  marcado_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_vehiculo_disp_empresa ON public.vehiculo_disponibilidad(empresa_id);

-- 16. Viaje dia control
CREATE TABLE public.viaje_dia_control (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  viaje_id UUID UNIQUE NOT NULL REFERENCES public.viajes(id),
  conductor_dia_finalizado_at TIMESTAMPTZ,
  conductor_dia_finalizado_by TEXT,
  conductor_dia_reabierto_at TIMESTAMPTZ,
  conductor_dia_reabierto_by TEXT,
  gerencia_dia_finalizado_at TIMESTAMPTZ,
  gerencia_dia_finalizado_by TEXT,
  gerencia_dia_reabierto_at TIMESTAMPTZ,
  gerencia_dia_reabierto_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================
-- SECURITY DEFINER FUNCTION FOR ROLES
-- ============================================
CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role public.app_role)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id AND role = _role
  )
$$;

-- Helper: get user's empresa_id
CREATE OR REPLACE FUNCTION public.get_user_empresa_id(_user_id UUID)
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT empresa_id FROM public.profiles
  WHERE user_id = _user_id
  LIMIT 1
$$;

-- ============================================
-- RLS POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invitaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conductores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.propietarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehiculos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asignaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.semanas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dias_operacion ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.viajes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ingresos_viaje ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.egresos_viaje ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehiculo_disponibilidad ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.viaje_dia_control ENABLE ROW LEVEL SECURITY;

-- Empresa: users can see their own empresa
CREATE POLICY "Users see own empresa" ON public.empresas
  FOR SELECT TO authenticated
  USING (id = public.get_user_empresa_id(auth.uid()));

-- Profiles: users see profiles in their empresa
CREATE POLICY "Users see empresa profiles" ON public.profiles
  FOR SELECT TO authenticated
  USING (empresa_id = public.get_user_empresa_id(auth.uid()));

CREATE POLICY "Users update own profile" ON public.profiles
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

-- User roles: users see their own roles
CREATE POLICY "Users see own roles" ON public.user_roles
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- Tenant-scoped policies for all operational tables
CREATE POLICY "Tenant access conductores" ON public.conductores
  FOR ALL TO authenticated
  USING (empresa_id = public.get_user_empresa_id(auth.uid()))
  WITH CHECK (empresa_id = public.get_user_empresa_id(auth.uid()));

CREATE POLICY "Tenant access propietarios" ON public.propietarios
  FOR ALL TO authenticated
  USING (empresa_id = public.get_user_empresa_id(auth.uid()))
  WITH CHECK (empresa_id = public.get_user_empresa_id(auth.uid()));

CREATE POLICY "Tenant access vehiculos" ON public.vehiculos
  FOR ALL TO authenticated
  USING (empresa_id = public.get_user_empresa_id(auth.uid()))
  WITH CHECK (empresa_id = public.get_user_empresa_id(auth.uid()));

CREATE POLICY "Tenant access asignaciones" ON public.asignaciones
  FOR ALL TO authenticated
  USING (empresa_id = public.get_user_empresa_id(auth.uid()))
  WITH CHECK (empresa_id = public.get_user_empresa_id(auth.uid()));

CREATE POLICY "Tenant access semanas" ON public.semanas
  FOR ALL TO authenticated
  USING (empresa_id = public.get_user_empresa_id(auth.uid()))
  WITH CHECK (empresa_id = public.get_user_empresa_id(auth.uid()));

CREATE POLICY "Tenant access dias_operacion" ON public.dias_operacion
  FOR ALL TO authenticated
  USING (empresa_id = public.get_user_empresa_id(auth.uid()))
  WITH CHECK (empresa_id = public.get_user_empresa_id(auth.uid()));

CREATE POLICY "Tenant access viajes" ON public.viajes
  FOR ALL TO authenticated
  USING (empresa_id = public.get_user_empresa_id(auth.uid()))
  WITH CHECK (empresa_id = public.get_user_empresa_id(auth.uid()));

CREATE POLICY "Tenant access ingresos" ON public.ingresos_viaje
  FOR ALL TO authenticated
  USING (empresa_id = public.get_user_empresa_id(auth.uid()))
  WITH CHECK (empresa_id = public.get_user_empresa_id(auth.uid()));

CREATE POLICY "Tenant access egresos" ON public.egresos_viaje
  FOR ALL TO authenticated
  USING (empresa_id = public.get_user_empresa_id(auth.uid()))
  WITH CHECK (empresa_id = public.get_user_empresa_id(auth.uid()));

CREATE POLICY "Tenant access audit" ON public.audit_logs
  FOR SELECT TO authenticated
  USING (empresa_id = public.get_user_empresa_id(auth.uid()));

CREATE POLICY "Tenant insert audit" ON public.audit_logs
  FOR INSERT TO authenticated
  WITH CHECK (empresa_id = public.get_user_empresa_id(auth.uid()));

CREATE POLICY "Tenant access vehiculo_disponibilidad" ON public.vehiculo_disponibilidad
  FOR ALL TO authenticated
  USING (empresa_id = public.get_user_empresa_id(auth.uid()))
  WITH CHECK (empresa_id = public.get_user_empresa_id(auth.uid()));

CREATE POLICY "Tenant access viaje_dia_control" ON public.viaje_dia_control
  FOR ALL TO authenticated
  USING (empresa_id = public.get_user_empresa_id(auth.uid()))
  WITH CHECK (empresa_id = public.get_user_empresa_id(auth.uid()));

CREATE POLICY "Tenant access invitaciones" ON public.invitaciones
  FOR ALL TO authenticated
  USING (empresa_id = public.get_user_empresa_id(auth.uid()))
  WITH CHECK (empresa_id = public.get_user_empresa_id(auth.uid()));

-- ============================================
-- TRIGGER: auto-update updated_at
-- ============================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER update_semanas_updated_at BEFORE UPDATE ON public.semanas FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_dias_operacion_updated_at BEFORE UPDATE ON public.dias_operacion FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_ingresos_updated_at BEFORE UPDATE ON public.ingresos_viaje FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_egresos_updated_at BEFORE UPDATE ON public.egresos_viaje FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_vehiculo_disp_updated_at BEFORE UPDATE ON public.vehiculo_disponibilidad FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_viaje_dia_control_updated_at BEFORE UPDATE ON public.viaje_dia_control FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- TRIGGER: auto-create profile on signup
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (user_id, empresa_id, username, email)
  VALUES (
    NEW.id,
    (NEW.raw_user_meta_data->>'empresa_id')::UUID,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    NEW.email
  );
  
  INSERT INTO public.user_roles (user_id, role)
  VALUES (
    NEW.id,
    (NEW.raw_user_meta_data->>'role')::public.app_role
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
