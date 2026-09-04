-- RLS coverage gate (doc 02 §16, doc 09 §2).
-- Along application tables in public/private must have RLS enabled.
-- Extension-owned catalog tables (e.g. PostGIS spatial_ref_sys) are excluded via pg_depend.
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
    AND NOT c.relispartition  -- partition children inherit parent RLS policies
    AND NOT c.relrowsecurity
    AND NOT EXISTS (
      SELECT 1
      FROM pg_depend d
      WHERE d.classid = 'pg_class'::regclass
        AND d.objid = c.oid
        AND d.refobjid IN (SELECT oid FROM pg_extension)
        AND d.deptype = 'e'
    );

  IF missing IS NOT NULL THEN
    RAISE EXCEPTION 'RLS coverage check failed — tables without RLS: %', missing;
  END IF;
END $$;
