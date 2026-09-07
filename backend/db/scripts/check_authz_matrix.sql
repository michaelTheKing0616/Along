-- Authorization matrix gate (P11-A-01, doc 02 §16 non-negotiables).
\set ON_ERROR_STOP on

DO $$
DECLARE
  missing_rls text;
  private_no_rls text;
  rider_presence int;
  bad_profile_admin int;
  bad_rider_admin int;
  bad_trips_city_admin int;
BEGIN
  -- Every Along application table in public/private must have RLS enabled.
  SELECT string_agg(format('%I.%I', n.nspname, c.relname), ', ' ORDER BY n.nspname, c.relname)
  INTO missing_rls
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE c.relkind = 'r'
    AND n.nspname IN ('public', 'private')
    AND NOT c.relispartition
    AND NOT c.relrowsecurity
    AND NOT EXISTS (
      SELECT 1
      FROM pg_depend d
      WHERE d.classid = 'pg_class'::regclass
        AND d.objid = c.oid
        AND d.refobjid IN (SELECT oid FROM pg_extension)
        AND d.deptype = 'e'
    );

  IF missing_rls IS NOT NULL THEN
    RAISE EXCEPTION 'authz matrix: tables without RLS: %', missing_rls;
  END IF;

  -- private.* must not expose policies to anon/authenticated (service role only).
  SELECT string_agg(format('%I.%I', schemaname, tablename), ', ' ORDER BY schemaname, tablename)
  INTO private_no_rls
  FROM pg_policies p
  WHERE p.schemaname = 'private'
    AND p.roles && array['anon', 'authenticated']::name[];

  IF private_no_rls IS NOT NULL THEN
    RAISE EXCEPTION 'authz matrix: private tables with anon/authenticated policies: %', private_no_rls;
  END IF;

  -- driver_presence: zero rider-readable policies (no SELECT unless driver own or admin).
  SELECT count(*)::int
  INTO rider_presence
  FROM pg_policies p
  WHERE p.schemaname = 'public'
    AND p.tablename = 'driver_presence'
    AND p.cmd IN ('SELECT', 'ALL')
    AND p.roles @> array['authenticated']::name[]
    AND coalesce(p.qual, '') NOT IN ('false', '(false)')
    AND coalesce(p.qual, '') NOT LIKE '%driver_id = auth.uid()%'
    AND coalesce(p.qual, '') NOT LIKE '%has_admin_role%';

  IF rider_presence > 0 THEN
    RAISE EXCEPTION 'authz matrix: driver_presence has % rider-readable SELECT policies', rider_presence;
  END IF;

  -- profiles admin policy must be city-scoped via admin_can_access_profile.
  SELECT count(*)::int
  INTO bad_profile_admin
  FROM pg_policies p
  WHERE p.schemaname = 'public'
    AND p.tablename = 'profiles'
    AND p.policyname = 'profiles_select_admin'
    AND coalesce(p.qual, '') NOT LIKE '%admin_can_access_profile%';

  IF bad_profile_admin > 0 THEN
    RAISE EXCEPTION 'authz matrix: profiles_select_admin missing admin_can_access_profile scope';
  END IF;

  -- riders admin policy must be city-scoped.
  SELECT count(*)::int
  INTO bad_rider_admin
  FROM pg_policies p
  WHERE p.schemaname = 'public'
    AND p.tablename = 'riders'
    AND p.policyname = 'riders_select_admin'
    AND coalesce(p.qual, '') NOT LIKE '%admin_can_access_city%';

  IF bad_rider_admin > 0 THEN
    RAISE EXCEPTION 'authz matrix: riders_select_admin missing admin_can_access_city scope';
  END IF;

  -- trips admin policy must include city_admin role (P9-A-01 parity with journeys).
  SELECT count(*)::int
  INTO bad_trips_city_admin
  FROM pg_policies p
  WHERE p.schemaname = 'public'
    AND p.tablename = 'trips'
    AND p.policyname = 'trips_select_admin'
    AND coalesce(p.qual, '') NOT LIKE '%city_admin%';

  IF bad_trips_city_admin > 0 THEN
    RAISE EXCEPTION 'authz matrix: trips_select_admin missing city_admin role';
  END IF;
END $$;
