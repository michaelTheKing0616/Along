-- P4-A-02: standing ladder, threshold policy, guarantors, notifications,
-- trip_reconciliation_flags schema (FM13 — flags never transition standing).

-- ---------------------------------------------------------------------------
-- Integrity flag types + table (doc 02 §10 — schema only; reconcile job is P4-A-06)
-- ---------------------------------------------------------------------------
create type flag_type as enum (
  'premature_conversion',
  'undeclared_extension',
  'route_deviation',
  'profile_price_mismatch'
);

create type flag_status as enum ('open', 'cleared', 'actioned');

create type trace_quality as enum ('none', 'partial', 'good');

create table trip_reconciliation_flags (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references trips(id),
  driver_id uuid not null references drivers(id),
  flag_type flag_type not null,
  score numeric(5,4) not null,
  evidence jsonb not null,
  rider_trace_quality trace_quality not null,
  corroborating_rider_count smallint not null default 0,
  status flag_status not null default 'open',
  reviewed_by uuid references admin_users(id),
  reviewed_at timestamptz,
  review_note text,
  created_at timestamptz not null default now(),
  unique (trip_id, flag_type)
);

create index trf_queue on trip_reconciliation_flags(status, score desc) where status = 'open';

alter table trip_reconciliation_flags enable row level security;

create policy trip_reconciliation_flags_select_admin
  on trip_reconciliation_flags for select to authenticated
  using (
    has_admin_role(array['superadmin', 'safety', 'ops_lead', 'finance'])
    and admin_can_access_city((
      select d.city_id from drivers d where d.id = driver_id
    ))
  );

create policy trip_reconciliation_flags_no_client_write
  on trip_reconciliation_flags for all to authenticated
  using (false)
  with check (false);

grant select on trip_reconciliation_flags to authenticated;

-- ---------------------------------------------------------------------------
-- Standing transitions (doc 02 §9)
-- ---------------------------------------------------------------------------
create table driver_standing_transitions (
  id bigserial primary key,
  driver_id uuid not null references drivers(id),
  from_standing driver_standing,
  to_standing driver_standing not null,
  actor_type actor_type not null,
  actor_id uuid,
  reason text not null,
  balance_at numeric(12,2),
  created_at timestamptz not null default now()
);

create index dst_driver_created on driver_standing_transitions(driver_id, created_at desc);

create trigger dst_ro before update or delete on driver_standing_transitions
  for each row execute function forbid_mutation();

alter table driver_standing_transitions enable row level security;

create policy driver_standing_transitions_select_own
  on driver_standing_transitions for select to authenticated
  using (driver_id = auth.uid());

create policy driver_standing_transitions_select_admin
  on driver_standing_transitions for select to authenticated
  using (
    has_admin_role(array['superadmin', 'safety', 'ops_lead', 'ops_agent', 'finance'])
    and admin_can_access_city((
      select d.city_id from drivers d where d.id = driver_id
    ))
  );

create policy driver_standing_transitions_no_client_write
  on driver_standing_transitions for all to authenticated
  using (false)
  with check (false);

grant select on driver_standing_transitions to authenticated;

-- ---------------------------------------------------------------------------
-- Guarantors (doc 02 §9 — notification only; no automatic deduction)
-- ---------------------------------------------------------------------------
create type guarantor_type as enum ('fellow_driver', 'vehicle_owner');

create table guarantors (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references drivers(id),
  guarantor_type guarantor_type not null,
  guarantor_profile_id uuid references profiles(id),
  guarantor_name text not null,
  guarantor_phone_e164 text not null,
  acknowledged_at timestamptz,
  last_notified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger guarantors_set_updated_at before update on guarantors
  for each row execute function set_updated_at();

alter table guarantors enable row level security;

create policy guarantors_select_own
  on guarantors for select to authenticated
  using (driver_id = auth.uid());

create policy guarantors_insert_own
  on guarantors for insert to authenticated
  with check (driver_id = auth.uid());

create policy guarantors_select_admin
  on guarantors for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'finance'])
    and admin_can_access_city((
      select d.city_id from drivers d where d.id = driver_id
    ))
  );

create policy guarantors_no_client_update_delete
  on guarantors for update to authenticated
  using (false)
  with check (false);

grant select, insert on guarantors to authenticated;

create table private.guarantor_ack_tokens (
  guarantor_id uuid primary key references guarantors(id) on delete cascade,
  token_hash bytea not null unique,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

revoke all on private.guarantor_ack_tokens from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Notifications (doc 02 §15)
-- ---------------------------------------------------------------------------
create table notifications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  type text not null,
  payload jsonb not null,
  channels text[] not null default '{push}',
  sent_at timestamptz,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index notifications_profile_created on notifications(profile_id, created_at desc);

alter table notifications enable row level security;

create policy notifications_select_own
  on notifications for select to authenticated
  using (profile_id = auth.uid());

create policy notifications_no_client_write
  on notifications for all to authenticated
  using (false)
  with check (false);

grant select on notifications to authenticated;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
create or replace function private.standing_rank(p_standing driver_standing)
returns int
language sql
immutable
as $$
  select case p_standing
    when 'good_standing' then 0
    when 'warned' then 1
    when 'matching_paused' then 2
    when 'guarantor_referred' then 3
    when 'deactivated' then 4
  end
$$;

create or replace function private.is_balance_standing_reason(p_reason text)
returns boolean
language sql
immutable
as $$
  select p_reason in (
    'balance_below_warn_threshold',
    'balance_below_block_threshold',
    'balance_restored'
  )
$$;

create or replace function private.driver_deposit_held(p_driver_id uuid)
returns numeric
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(sum(dle.amount), 0)
  from driver_ledger_entries dle
  where dle.driver_id = p_driver_id
    and dle.entry_type in ('onboarding_deposit', 'deposit_drawdown')
$$;

create or replace function private.driver_ledger_balance(p_driver_id uuid)
returns numeric
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((
    select sum(db.balance)
    from driver_balances db
    where db.driver_id = p_driver_id
  ), 0)
$$;

create or replace function private.notify_standing_changed(
  p_driver_id uuid,
  p_from_standing driver_standing,
  p_to_standing driver_standing,
  p_reason text,
  p_balance numeric,
  p_city_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_grace_hours numeric;
  v_grace_deadline timestamptz;
begin
  v_grace_hours := cfg_num('ledger.grace_period_hours', p_city_id);

  if p_to_standing = 'warned' then
    v_grace_deadline := now() + make_interval(hours => v_grace_hours::int);
  end if;

  insert into notifications (profile_id, type, payload, channels)
  values (
    p_driver_id,
    'standing_changed',
    jsonb_build_object(
      'from_standing', p_from_standing,
      'to_standing', p_to_standing,
      'reason', p_reason,
      'balance_at', p_balance,
      'block_threshold', cfg_num('ledger.block_threshold', p_city_id),
      'warn_threshold', cfg_num('ledger.warn_threshold', p_city_id),
      'settle_cta', 'Settle your balance to restore good standing',
      'grace_deadline', v_grace_deadline
    ),
    array['push', 'inapp']
  );
end;
$$;

create or replace function private.notify_ops_standing_review(
  p_driver_id uuid,
  p_reason text,
  p_balance numeric
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into notifications (profile_id, type, payload, channels)
  select
    a.id,
    'standing_review_required',
    jsonb_build_object(
      'driver_id', p_driver_id,
      'reason', p_reason,
      'balance_at', p_balance,
      'message', 'Driver requires human review for deactivation or guarantor referral — never automatic'
    ),
    array['inapp']
  from admin_users a
  join drivers d on d.id = p_driver_id
  join cities c on c.id = d.city_id
  join countries k on k.code = c.country_code
  where a.disabled_at is null
    and a.role in ('ops_lead', 'superadmin')
    and (
      a.role = 'superadmin'
      or a.deployment_id = k.deployment_id
      or d.city_id = any(a.city_scope)
    )
    and not exists (
      select 1
      from notifications n
      where n.profile_id = a.id
        and n.type = 'standing_review_required'
        and n.payload->>'driver_id' = p_driver_id::text
        and n.created_at > now() - interval '1 day'
    );
end;
$$;

-- ---------------------------------------------------------------------------
-- transition_standing — doc 04 §12.4
-- ---------------------------------------------------------------------------
create or replace function transition_standing(
  p_driver_id uuid,
  p_to_standing driver_standing,
  p_actor_type actor_type,
  p_actor_id uuid,
  p_reason text
)
returns driver_standing_transitions
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_driver drivers%rowtype;
  v_from driver_standing;
  v_balance numeric;
  v_row driver_standing_transitions%rowtype;
  v_from_rank int;
  v_to_rank int;
  v_last_reason text;
begin
  if p_reason is null or btrim(p_reason) = '' then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'reason is required';
  end if;

  select * into v_driver
  from drivers
  where id = p_driver_id
  for update;

  if v_driver.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  v_from := v_driver.standing;
  if v_from = p_to_standing then
    select * into v_row
    from driver_standing_transitions
    where driver_id = p_driver_id
    order by id desc
    limit 1;
    return v_row;
  end if;

  v_from_rank := private.standing_rank(v_from);
  v_to_rank := private.standing_rank(p_to_standing);
  v_balance := private.driver_ledger_balance(p_driver_id);

  if p_actor_type = 'system' then
    if p_to_standing = 'good_standing' then
      if v_from not in ('warned', 'matching_paused') then
        raise exception 'FORBIDDEN' using errcode = 'P0001', message = 'system may only restore good_standing from warned or matching_paused';
      end if;
      if p_reason <> 'balance_restored' then
        raise exception 'FORBIDDEN' using errcode = 'P0001', message = 'system restoration requires balance_restored reason';
      end if;
    elsif p_to_standing in ('warned', 'matching_paused') then
      if v_to_rank <= v_from_rank then
        raise exception 'FORBIDDEN' using errcode = 'P0001', message = 'system downward transition must advance standing severity';
      end if;
      if p_to_standing = 'warned' and v_from <> 'good_standing' then
        raise exception 'FORBIDDEN' using errcode = 'P0001', message = 'system may only warn from good_standing';
      end if;
      if p_to_standing = 'matching_paused' and v_from not in ('good_standing', 'warned') then
        raise exception 'FORBIDDEN' using errcode = 'P0001', message = 'system may only pause matching from good_standing or warned';
      end if;
    else
      raise exception 'FORBIDDEN' using errcode = 'P0001', message = 'system actor cannot transition to this standing';
    end if;
  elsif p_actor_type = 'admin' then
    if v_to_rank < v_from_rank then
      if p_to_standing = 'good_standing' and v_from = 'deactivated' and v_balance < 0 then
        raise exception 'STATE_INVALID' using errcode = 'P0001', message = 'reactivation requires balance >= 0';
      end if;
    elsif v_to_rank > v_from_rank then
      if v_from_rank < private.standing_rank('matching_paused') then
        raise exception 'FORBIDDEN' using errcode = 'P0001',
          message = 'threshold ladder steps below matching_paused are system-only';
      end if;
      if v_to_rank - v_from_rank <> 1 then
        raise exception 'FORBIDDEN' using errcode = 'P0001',
          message = 'admin downward standing transition must advance one step at a time';
      end if;
    end if;
  else
    raise exception 'FORBIDDEN' using errcode = 'P0001', message = 'only system or admin may transition standing';
  end if;

  update drivers
  set standing = p_to_standing, standing_since = now(), updated_at = now()
  where id = p_driver_id;

  insert into driver_standing_transitions (
    driver_id, from_standing, to_standing, actor_type, actor_id, reason, balance_at
  ) values (
    p_driver_id, v_from, p_to_standing, p_actor_type, p_actor_id, p_reason, v_balance
  )
  returning * into v_row;

  perform private.notify_standing_changed(
    p_driver_id, v_from, p_to_standing, p_reason, v_balance, v_driver.city_id
  );

  return v_row;
end;
$$;

revoke all on function transition_standing(uuid, driver_standing, actor_type, uuid, text) from public;
grant execute on function transition_standing(uuid, driver_standing, actor_type, uuid, text)
  to service_role;

-- ---------------------------------------------------------------------------
-- apply_threshold_policy — doc 04 §12.3 (system actor; never flag-driven)
-- ---------------------------------------------------------------------------
create or replace function apply_threshold_policy()
returns void
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_rec record;
  v_block numeric;
  v_warn numeric;
  v_deactivate numeric;
  v_grace_hours numeric;
  v_deactivate_days numeric;
  v_deposit numeric;
  v_drawdown numeric;
  v_last_reason text;
  v_needs_review boolean;
begin
  for v_rec in
    select
      d.id as driver_id,
      d.standing,
      d.standing_since,
      d.city_id,
      private.driver_ledger_balance(d.id) as balance
    from drivers d
  loop
    v_block := cfg_num('ledger.block_threshold', v_rec.city_id);
    v_warn := cfg_num('ledger.warn_threshold', v_rec.city_id);
    v_deactivate := cfg_num('ledger.deactivate_threshold', v_rec.city_id);
    v_grace_hours := cfg_num('ledger.grace_period_hours', v_rec.city_id);
    v_deactivate_days := cfg_num('ledger.deactivate_after_days', v_rec.city_id);

    if v_rec.balance <= v_block
       and v_rec.standing in ('good_standing', 'warned') then
      perform transition_standing(
        v_rec.driver_id,
        'matching_paused',
        'system',
        null,
        'balance_below_block_threshold'
      );
    elsif v_rec.balance <= v_warn
       and v_rec.standing = 'good_standing' then
      perform transition_standing(
        v_rec.driver_id,
        'warned',
        'system',
        null,
        'balance_below_warn_threshold'
      );
    elsif v_rec.balance > v_warn
       and v_rec.standing in ('warned', 'matching_paused') then
      select dst.reason into v_last_reason
      from driver_standing_transitions dst
      where dst.driver_id = v_rec.driver_id
      order by dst.id desc
      limit 1;

      if private.is_balance_standing_reason(v_last_reason)
         and v_last_reason <> 'balance_restored' then
        perform transition_standing(
          v_rec.driver_id,
          'good_standing',
          'system',
          null,
          'balance_restored'
        );
      end if;
    end if;

    select standing, standing_since
    into v_rec.standing, v_rec.standing_since
    from drivers
    where id = v_rec.driver_id;

    if v_rec.standing = 'matching_paused'
       and v_rec.standing_since <= now() - make_interval(hours => v_grace_hours::int) then
      v_deposit := private.driver_deposit_held(v_rec.driver_id);
      if v_deposit > 0 and v_rec.balance < 0 then
        v_drawdown := least(v_deposit, -v_rec.balance);
        perform ledger_post(
          v_rec.driver_id,
          'deposit_drawdown',
          -v_drawdown,
          'NGN',
          '{}'::jsonb,
          format(
            'deposit_drawdown:%s:%s',
            v_rec.driver_id,
            to_char(v_rec.standing_since, 'YYYYMMDDHH24MISS')
          ),
          'system',
          null,
          'Automatic deposit drawdown after grace period'
        );
      end if;
    end if;

    v_needs_review := v_rec.balance <= v_deactivate
      or (
        v_rec.standing = 'matching_paused'
        and v_rec.standing_since <= now() - make_interval(days => v_deactivate_days::int)
      );

    if v_needs_review then
      perform private.notify_ops_standing_review(
        v_rec.driver_id,
        case
          when v_rec.balance <= v_deactivate then 'balance_below_deactivate_threshold'
          else 'matching_paused_exceeded_deactivate_after_days'
        end,
        v_rec.balance
      );
    end if;
  end loop;
end;
$$;

revoke all on function apply_threshold_policy() from public;
grant execute on function apply_threshold_policy() to service_role;

-- ---------------------------------------------------------------------------
-- Driver RPCs (doc 03 §7)
-- ---------------------------------------------------------------------------
create or replace function my_standing_history()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'from_standing', dst.from_standing,
        'to_standing', dst.to_standing,
        'actor_type', dst.actor_type,
        'reason', dst.reason,
        'balance_at', dst.balance_at::text,
        'created_at', dst.created_at
      )
      order by dst.created_at desc
    ),
    '[]'::jsonb
  )
  from driver_standing_transitions dst
  where dst.driver_id = auth.uid()
$$;

grant execute on function my_standing_history() to authenticated;

create or replace function register_guarantor(
  p_guarantor_type guarantor_type,
  p_name text,
  p_phone_e164 text,
  p_profile_id uuid default null
)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, private, extensions
as $$
declare
  v_driver_id uuid := auth.uid();
  v_guarantor_id uuid;
  v_token text;
  v_token_hash bytea;
  v_origin text;
  v_link text;
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if p_name is null or btrim(p_name) = '' then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if p_phone_e164 is null or btrim(p_phone_e164) = '' then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  insert into guarantors (
    driver_id,
    guarantor_type,
    guarantor_profile_id,
    guarantor_name,
    guarantor_phone_e164
  ) values (
    v_driver_id,
    p_guarantor_type,
    p_profile_id,
    btrim(p_name),
    btrim(p_phone_e164)
  )
  returning id into v_guarantor_id;

  v_token := encode(gen_random_bytes(32), 'base64');
  v_token_hash := digest(v_token, 'sha256');

  insert into private.guarantor_ack_tokens (guarantor_id, token_hash, expires_at)
  values (v_guarantor_id, v_token_hash, now() + interval '7 days');

  v_origin := nullif(btrim(cfg('public.origin', null)::text), '');
  if v_origin is not null and v_origin <> '""' then
    v_link := rtrim(trim(both '"' from v_origin), '/') || '/guarantor/' || v_token;
  else
    v_link := '/guarantor/' || v_token;
  end if;

  if p_profile_id is not null then
    insert into notifications (profile_id, type, payload, channels)
    values (
      p_profile_id,
      'guarantor_referral',
      jsonb_build_object(
        'driver_id', v_driver_id,
        'guarantor_id', v_guarantor_id,
        'acknowledgement_link', v_link
      ),
      array['inapp']
    );
  end if;

  return v_guarantor_id;
end;
$$;

grant execute on function register_guarantor(guarantor_type, text, text, uuid) to authenticated;

create or replace function acknowledge_guarantor(p_token text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, private, extensions
as $$
declare
  v_guarantor guarantors%rowtype;
  v_ack timestamptz := now();
begin
  if p_token is null or btrim(p_token) = '' then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  select g.* into v_guarantor
  from guarantors g
  join private.guarantor_ack_tokens t on t.guarantor_id = g.id
  where t.token_hash = digest(btrim(p_token), 'sha256')
    and t.expires_at > now()
  for update of g;

  if v_guarantor.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_guarantor.acknowledged_at is null then
    update guarantors
    set acknowledged_at = v_ack, updated_at = now()
    where id = v_guarantor.id;
  else
    v_ack := v_guarantor.acknowledged_at;
  end if;

  delete from private.guarantor_ack_tokens where guarantor_id = v_guarantor.id;

  return jsonb_build_object('acknowledged_at', v_ack);
end;
$$;

grant execute on function acknowledge_guarantor(text) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- Admin RPCs (doc 03 §11)
-- ---------------------------------------------------------------------------
create or replace function admin_transition_standing(
  p_driver_id uuid,
  p_to text,
  p_reason text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_to driver_standing;
  v_row driver_standing_transitions%rowtype;
begin
  if not has_admin_role(array['ops_lead', 'finance']) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if not admin_can_access_city((
    select d.city_id from drivers d where d.id = p_driver_id
  )) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  begin
    v_to := p_to::driver_standing;
  exception
    when invalid_text_representation then
      raise exception 'VALIDATION' using errcode = 'P0001', message = 'invalid standing';
  end;

  v_row := transition_standing(p_driver_id, v_to, 'admin', auth.uid(), p_reason);

  return jsonb_build_object(
    'transition_id', v_row.id,
    'from_standing', v_row.from_standing,
    'to_standing', v_row.to_standing,
    'reason', v_row.reason
  );
end;
$$;

grant execute on function admin_transition_standing(uuid, text, text) to authenticated;

create or replace function admin_notify_guarantor(p_driver_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_guarantor guarantors%rowtype;
begin
  if not has_admin_role(array['ops_lead']) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if not admin_can_access_city((
    select d.city_id from drivers d where d.id = p_driver_id
  )) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  select * into v_guarantor
  from guarantors g
  where g.driver_id = p_driver_id
  order by g.created_at desc
  limit 1;

  if v_guarantor.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001', message = 'no guarantor registered';
  end if;

  update guarantors
  set last_notified_at = now(), updated_at = now()
  where id = v_guarantor.id;

  if v_guarantor.guarantor_profile_id is not null then
    insert into notifications (profile_id, type, payload, channels)
    values (
      v_guarantor.guarantor_profile_id,
      'guarantor_referral',
      jsonb_build_object(
        'driver_id', p_driver_id,
        'guarantor_id', v_guarantor.id,
        'guarantor_name', v_guarantor.guarantor_name,
        'message', 'A driver you guaranteed has been referred for guarantor follow-up. Nothing is deducted from your balance.'
      ),
      array['push', 'inapp', 'sms']
    );
  end if;

  return jsonb_build_object(
    'guarantor_id', v_guarantor.id,
    'last_notified_at', now()
  );
end;
$$;

grant execute on function admin_notify_guarantor(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- pg_cron — every 10 min (doc 03 §12)
-- ---------------------------------------------------------------------------
do $$
declare
  v_jobid bigint;
begin
  for v_jobid in select jobid from cron.job where jobname = 'apply_threshold_policy' loop
    perform cron.unschedule(v_jobid);
  end loop;
  perform cron.schedule(
    'apply_threshold_policy',
    '*/10 * * * *',
    $cron$select apply_threshold_policy()$cron$
  );
exception
  when undefined_table then
    raise notice 'pg_cron unavailable — schedule apply_threshold_policy manually (doc 03 §12)';
  when others then
    raise notice 'pg_cron schedule skipped: %', sqlerrm;
end;
$$;
