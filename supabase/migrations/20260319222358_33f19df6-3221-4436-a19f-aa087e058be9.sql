
-- Create storage bucket for conductor documents (profile photo, ID, license)
INSERT INTO storage.buckets (id, name, public) VALUES ('conductor-docs', 'conductor-docs', true)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload to conductor-docs
CREATE POLICY "Authenticated users can upload conductor docs"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'conductor-docs');

-- Allow authenticated users to read conductor docs
CREATE POLICY "Authenticated users can read conductor docs"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'conductor-docs');

-- Allow users to update their own uploads
CREATE POLICY "Authenticated users can update conductor docs"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'conductor-docs');

-- Add photo/document columns to conductores table
ALTER TABLE public.conductores
ADD COLUMN IF NOT EXISTS foto_url text,
ADD COLUMN IF NOT EXISTS cedula_frontal_url text,
ADD COLUMN IF NOT EXISTS cedula_trasera_url text,
ADD COLUMN IF NOT EXISTS licencia_frontal_url text,
ADD COLUMN IF NOT EXISTS licencia_trasera_url text;
