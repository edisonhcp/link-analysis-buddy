
CREATE TABLE public.vehiculo_alimentacion (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL REFERENCES public.empresas(id),
  vehiculo_id uuid NOT NULL REFERENCES public.vehiculos(id) ON DELETE CASCADE,
  valor_comida numeric NOT NULL DEFAULT 3,
  desayuno_habilitado boolean NOT NULL DEFAULT true,
  almuerzo_habilitado boolean NOT NULL DEFAULT true,
  merienda_habilitado boolean NOT NULL DEFAULT true,
  alimentacion_habilitada boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(vehiculo_id)
);

ALTER TABLE public.vehiculo_alimentacion ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tenant access vehiculo_alimentacion"
  ON public.vehiculo_alimentacion
  FOR ALL
  TO authenticated
  USING (empresa_id = get_user_empresa_id(auth.uid()))
  WITH CHECK (empresa_id = get_user_empresa_id(auth.uid()));
