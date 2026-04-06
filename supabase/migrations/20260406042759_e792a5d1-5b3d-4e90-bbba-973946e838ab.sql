
CREATE POLICY "Super admin see all semanas"
ON public.semanas
FOR SELECT
TO authenticated
USING (has_role(auth.uid(), 'SUPER_ADMIN'::app_role));

CREATE POLICY "Super admin see all dias_operacion"
ON public.dias_operacion
FOR SELECT
TO authenticated
USING (has_role(auth.uid(), 'SUPER_ADMIN'::app_role));

CREATE POLICY "Super admin see all viaje_dia_control"
ON public.viaje_dia_control
FOR SELECT
TO authenticated
USING (has_role(auth.uid(), 'SUPER_ADMIN'::app_role));
