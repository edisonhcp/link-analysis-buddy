
-- Remove duplicate old FKs (NO ACTION ones where we have new specific ones)
ALTER TABLE asignaciones DROP CONSTRAINT IF EXISTS asignaciones_conductor_id_fkey;
ALTER TABLE asignaciones DROP CONSTRAINT IF EXISTS asignaciones_vehiculo_id_fkey;
ALTER TABLE dias_operacion DROP CONSTRAINT IF EXISTS dias_operacion_semana_id_fkey;
ALTER TABLE egresos_viaje DROP CONSTRAINT IF EXISTS egresos_viaje_viaje_id_fkey;
ALTER TABLE ingresos_viaje DROP CONSTRAINT IF EXISTS ingresos_viaje_viaje_id_fkey;
ALTER TABLE semanas DROP CONSTRAINT IF EXISTS semanas_vehiculo_id_fkey;
ALTER TABLE semanas DROP CONSTRAINT IF EXISTS semanas_propietario_id_fkey;
ALTER TABLE vehiculos DROP CONSTRAINT IF EXISTS vehiculos_propietario_id_fkey;
ALTER TABLE vehiculo_disponibilidad DROP CONSTRAINT IF EXISTS vehiculo_disponibilidad_vehiculo_id_fkey;
ALTER TABLE vehiculo_alimentacion DROP CONSTRAINT IF EXISTS vehiculo_alimentacion_vehiculo_id_fkey;
ALTER TABLE viaje_dia_control DROP CONSTRAINT IF EXISTS viaje_dia_control_viaje_id_fkey;
ALTER TABLE viajes DROP CONSTRAINT IF EXISTS viajes_asignacion_id_fkey;
ALTER TABLE viajes DROP CONSTRAINT IF EXISTS viajes_semana_id_fkey;
ALTER TABLE viajes DROP CONSTRAINT IF EXISTS viajes_dia_operacion_id_fkey;

-- Remove duplicate profiles FKs (keep the new _fk ones)
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS fk_profiles_conductor;
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS fk_profiles_propietario;

-- Remove duplicate invitaciones FK
ALTER TABLE invitaciones DROP CONSTRAINT IF EXISTS invitaciones_empresa_id_fkey;

-- CRITICAL: Remove CASCADE empresa_id FKs from operational tables
-- These would delete all historical data when an empresa is removed
ALTER TABLE conductores DROP CONSTRAINT IF EXISTS conductores_empresa_id_fkey;
ALTER TABLE vehiculos DROP CONSTRAINT IF EXISTS vehiculos_empresa_id_fkey;
ALTER TABLE viajes DROP CONSTRAINT IF EXISTS viajes_empresa_id_fkey;
ALTER TABLE ingresos_viaje DROP CONSTRAINT IF EXISTS ingresos_viaje_empresa_id_fkey;
ALTER TABLE egresos_viaje DROP CONSTRAINT IF EXISTS egresos_viaje_empresa_id_fkey;
ALTER TABLE propietarios DROP CONSTRAINT IF EXISTS propietarios_empresa_id_fkey;
ALTER TABLE asignaciones DROP CONSTRAINT IF EXISTS asignaciones_empresa_id_fkey;
ALTER TABLE semanas DROP CONSTRAINT IF EXISTS semanas_empresa_id_fkey;
ALTER TABLE dias_operacion DROP CONSTRAINT IF EXISTS dias_operacion_empresa_id_fkey;
ALTER TABLE audit_logs DROP CONSTRAINT IF EXISTS audit_logs_empresa_id_fkey;
ALTER TABLE viaje_dia_control DROP CONSTRAINT IF EXISTS viaje_dia_control_empresa_id_fkey;
ALTER TABLE vehiculo_alimentacion DROP CONSTRAINT IF EXISTS vehiculo_alimentacion_empresa_id_fkey;
ALTER TABLE vehiculo_disponibilidad DROP CONSTRAINT IF EXISTS vehiculo_disponibilidad_empresa_id_fkey;
