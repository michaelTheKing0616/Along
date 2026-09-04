-- RLS coverage gate (doc 09 §2, doc 02 §16).
-- Fails if any user table in Along-owned schemas lacks row-level security.
\set ON_ERROR_STOP on

DO $$
DECLARE
  missing text;
BEGIN
  SELECT string_agg(format('%I.%I', n.nspname, c.relname), ', ' ORDER BY n.nspname, c.relname)
  INTO missing
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE c.relkind = 'r'
    AND n.nspname IN ('public', 'private')
    AND NOT c.relrowsecurity;

  IF missing IS NOT NULL THEN
    RAISE EXCEPTION 'RLS coverage check failed — tables without RLS: %', missing;
  END IF;
END $$;
