
-- Table for agency deregistration requests
CREATE TABLE public.solicitudes_baja (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  empresa_id UUID NOT NULL,
  solicitado_por UUID NOT NULL,
  motivo TEXT NOT NULL DEFAULT '',
  estado TEXT NOT NULL DEFAULT 'PENDIENTE',
  resuelto_por UUID,
  resuelto_at TIMESTAMP WITH TIME ZONE,
  motivo_rechazo TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.solicitudes_baja ENABLE ROW LEVEL SECURITY;

-- Super Admin can see and manage all requests
CREATE POLICY "Super admin manage solicitudes_baja"
ON public.solicitudes_baja
FOR ALL
TO authenticated
USING (has_role(auth.uid(), 'SUPER_ADMIN'::app_role))
WITH CHECK (has_role(auth.uid(), 'SUPER_ADMIN'::app_role));

-- Agency users can see their own requests
CREATE POLICY "Tenant see own solicitudes_baja"
ON public.solicitudes_baja
FOR SELECT
TO authenticated
USING (empresa_id = get_user_empresa_id(auth.uid()));

-- Agency users can insert their own requests
CREATE POLICY "Tenant insert solicitudes_baja"
ON public.solicitudes_baja
FOR INSERT
TO authenticated
WITH CHECK (empresa_id = get_user_empresa_id(auth.uid()));
