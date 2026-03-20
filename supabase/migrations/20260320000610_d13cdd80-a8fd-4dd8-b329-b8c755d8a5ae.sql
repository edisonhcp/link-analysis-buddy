
ALTER TABLE public.propietarios ADD COLUMN IF NOT EXISTS foto_url text;
ALTER TABLE public.vehiculos ADD COLUMN IF NOT EXISTS foto_url text;

INSERT INTO storage.buckets (id, name, public) VALUES ('propietario-docs', 'propietario-docs', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('vehiculo-fotos', 'vehiculo-fotos', true) ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Authenticated users can upload propietario docs" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'propietario-docs');
CREATE POLICY "Public read propietario docs" ON storage.objects FOR SELECT USING (bucket_id = 'propietario-docs');
CREATE POLICY "Authenticated users can update propietario docs" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'propietario-docs');

CREATE POLICY "Authenticated users can upload vehiculo fotos" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'vehiculo-fotos');
CREATE POLICY "Public read vehiculo fotos" ON storage.objects FOR SELECT USING (bucket_id = 'vehiculo-fotos');
CREATE POLICY "Authenticated users can update vehiculo fotos" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'vehiculo-fotos');
