
-- 1. Drop the overly permissive tenant INSERT on audit_logs
DROP POLICY IF EXISTS "Tenant insert audit" ON public.audit_logs;

-- Replace with GERENCIA-only insert
CREATE POLICY "Gerencia insert audit"
ON public.audit_logs
FOR INSERT
TO authenticated
WITH CHECK (
  empresa_id = get_user_empresa_id(auth.uid())
  AND (has_role(auth.uid(), 'GERENCIA'::app_role) OR has_role(auth.uid(), 'SUPER_ADMIN'::app_role))
);

-- 2. Drop the overly permissive tenant ALL on invitaciones
DROP POLICY IF EXISTS "Tenant access invitaciones" ON public.invitaciones;

-- Replace with GERENCIA-only access within tenant
CREATE POLICY "Gerencia access invitaciones"
ON public.invitaciones
FOR ALL
TO authenticated
USING (
  empresa_id = get_user_empresa_id(auth.uid())
  AND has_role(auth.uid(), 'GERENCIA'::app_role)
)
WITH CHECK (
  empresa_id = get_user_empresa_id(auth.uid())
  AND has_role(auth.uid(), 'GERENCIA'::app_role)
);
