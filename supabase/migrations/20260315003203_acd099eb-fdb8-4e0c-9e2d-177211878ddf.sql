
-- Add GERENCIA to invitacion_rol enum
ALTER TYPE public.invitacion_rol ADD VALUE IF NOT EXISTS 'GERENCIA';

-- Add activo column to empresas for suspend functionality
ALTER TABLE public.empresas ADD COLUMN IF NOT EXISTS activo boolean NOT NULL DEFAULT true;

-- Allow SUPER_ADMIN to delete empresas
CREATE POLICY "Super admin delete empresas"
ON public.empresas
FOR DELETE
TO authenticated
USING (has_role(auth.uid(), 'SUPER_ADMIN'::app_role));

-- Allow SUPER_ADMIN to manage invitaciones
CREATE POLICY "Super admin manage invitaciones"
ON public.invitaciones
FOR ALL
TO authenticated
USING (has_role(auth.uid(), 'SUPER_ADMIN'::app_role))
WITH CHECK (has_role(auth.uid(), 'SUPER_ADMIN'::app_role));
