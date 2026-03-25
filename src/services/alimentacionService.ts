import { supabase } from "@/integrations/supabase/client";

export interface VehiculoAlimentacion {
  id: string;
  vehiculo_id: string;
  empresa_id: string;
  valor_comida: number;
  desayuno_habilitado: boolean;
  almuerzo_habilitado: boolean;
  merienda_habilitado: boolean;
  alimentacion_habilitada: boolean;
}

export async function fetchAlimentacionConfig(vehiculoId: string) {
  const { data, error } = await supabase
    .from("vehiculo_alimentacion")
    .select("*")
    .eq("vehiculo_id", vehiculoId)
    .maybeSingle();
  return { data: data as VehiculoAlimentacion | null, error };
}

export async function upsertAlimentacionConfig(params: {
  vehiculo_id: string;
  empresa_id: string;
  valor_comida: number;
  desayuno_habilitado: boolean;
  almuerzo_habilitado: boolean;
  merienda_habilitado: boolean;
  alimentacion_habilitada: boolean;
}) {
  const { data: existing } = await supabase
    .from("vehiculo_alimentacion")
    .select("id")
    .eq("vehiculo_id", params.vehiculo_id)
    .maybeSingle();

  if (existing) {
    const { error } = await supabase
      .from("vehiculo_alimentacion")
      .update({
        valor_comida: params.valor_comida,
        desayuno_habilitado: params.desayuno_habilitado,
        almuerzo_habilitado: params.almuerzo_habilitado,
        merienda_habilitado: params.merienda_habilitado,
        alimentacion_habilitada: params.alimentacion_habilitada,
      })
      .eq("id", existing.id);
    return { error };
  } else {
    const { error } = await supabase
      .from("vehiculo_alimentacion")
      .insert(params);
    return { error };
  }
}

export async function fetchAlimentacionByVehiculos(vehiculoIds: string[]) {
  if (vehiculoIds.length === 0) return { data: [], error: null };
  const { data, error } = await supabase
    .from("vehiculo_alimentacion")
    .select("*")
    .in("vehiculo_id", vehiculoIds);
  return { data: (data || []) as VehiculoAlimentacion[], error };
}
