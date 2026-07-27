-- Seed the dev bypass user so the Go backend's dev auth fallback can write to
-- foreign-keyed tables (participants.id is uuid, referenced by expenses, lists, etc.)
--
-- The hardcoded UUIDs below must match auth.go's dev bypass values.

INSERT INTO public.participants (id, kind)
VALUES ('00000000-0000-0000-0000-000000000001', 'user')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (participant_id, user_id, display_name)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'b8c17831-3032-409f-a03d-3ca1d2415a3c',
  'Dev User'
)
ON CONFLICT (participant_id) DO NOTHING;
