import { supabase } from "@/integrations/supabase/client";

export async function fetchSolicitudPendiente(empresaId: string) {
  const { data } = await supabase
    .from("solicitudes_baja")
    .select("*")
    .eq("empresa_id", empresaId)
    .eq("estado", "PENDIENTE")
    .maybeSingle();
  return data;
}

export async function crearSolicitudBaja(empresaId: string, userId: string, motivo: string) {
  const { error } = await supabase
    .from("solicitudes_baja")
    .insert({ empresa_id: empresaId, solicitado_por: userId, motivo });
  return { error };
}

export async function fetchSolicitudesPendientes() {
  const { data } = await supabase
    .from("solicitudes_baja")
    .select("*, empresas(nombre)")
    .eq("estado", "PENDIENTE")
    .order("created_at", { ascending: false });
  return data || [];
}

export async function resolverSolicitud(id: string, estado: "APROBADA" | "RECHAZADA", resueltoPor: string, motivoRechazo?: string) {
  const { error } = await supabase
    .from("solicitudes_baja")
    .update({
      estado,
      resuelto_por: resueltoPor,
      resuelto_at: new Date().toISOString(),
      motivo_rechazo: motivoRechazo || null,
    })
    .eq("id", id);
  return { error };
}
