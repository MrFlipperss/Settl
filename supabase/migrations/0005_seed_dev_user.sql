-- Seed all participants used by the frontend mock data so that expenses
-- created from the app can reference valid participant UUIDs.
--
-- The dev bypass user (0000...001) must also match auth.go's hardcoded values.

INSERT INTO public.participants (id, kind) VALUES
  ('00000000-0000-0000-0000-000000000001', 'user'),
  ('00000000-0000-0000-0000-000000000002', 'user'),
  ('00000000-0000-0000-0000-000000000003', 'user'),
  ('00000000-0000-0000-0000-000000000004', 'user'),
  ('00000000-0000-0000-0000-000000000005', 'user')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (participant_id, user_id, display_name)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'b8c17831-3032-409f-a03d-3ca1d2415a3c',
  'Dev User'
)
ON CONFLICT (participant_id) DO NOTHING;
