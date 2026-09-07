-- Clone public key tables into scratch schema for local restore drill (TS-OPS-01).
-- Requires session GUC: set restore.scratch_schema = 'along_restore_scratch';

\set ON_ERROR_STOP on

do $$
declare
  v_schema text := current_setting('restore.scratch_schema');
begin
  execute format('drop schema if exists %I cascade', v_schema);
  execute format('create schema %I', v_schema);
end;
$$;

do $$
declare
  v_schema text := current_setting('restore.scratch_schema');
  v_table text;
  v_tables text[] := array[
    'cities', 'parks', 'routes', 'route_stages', 'route_legs', 'route_through_fares',
    'corridors', 'profiles', 'drivers', 'riders', 'trips', 'driver_ledger_entries',
    'payments', 'app_config', 'app_config_keys', 'deployments', 'countries'
  ];
begin
  foreach v_table in array v_tables loop
    if to_regclass(format('public.%I', v_table)) is null then
      raise exception 'restore drill: missing public.%', v_table;
    end if;

    execute format(
      'create table %I.%I (like public.%I including defaults including constraints including indexes)',
      v_schema, v_table, v_table
    );

    execute format(
      'insert into %I.%I select * from public.%I',
      v_schema, v_table, v_table
    );
  end loop;
end;
$$;
