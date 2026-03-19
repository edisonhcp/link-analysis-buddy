
CREATE POLICY "Super admin see all viajes"
ON public.viajes
FOR SELECT
TO authenticated
USING (has_role(auth.uid(), 'SUPER_ADMIN'::app_role));

CREATE POLICY "Super admin see all ingresos_viaje"
ON public.ingresos_viaje
FOR SELECT
TO authenticated
USING (has_role(auth.uid(), 'SUPER_ADMIN'::app_role));

CREATE POLICY "Super admin see all egresos_viaje"
ON public.egresos_viaje
FOR SELECT
TO authenticated
USING (has_role(auth.uid(), 'SUPER_ADMIN'::app_role));
