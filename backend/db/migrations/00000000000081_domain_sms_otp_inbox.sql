-- Log-mode SMS inbox so device smokes can complete OTP without Termii.
-- peek_log_otp is a no-op when cfg sms.provider is not 'log'.

create table if not exists private.sms_otp_inbox (
  phone text not null,
  otp text not null,
  created_at timestamptz not null default now()
);

create index if not exists sms_otp_inbox_phone_created_idx
  on private.sms_otp_inbox (phone, created_at desc);

create or replace function record_log_otp(p_phone text, p_otp text)
returns void
language plpgsql
security definer
set search_path = public, private, extensions
as $$
declare
  provider text;
begin
  provider := coalesce(cfg('sms.provider') #>> '{}', 'log');
  if provider is distinct from 'log' then
    return;
  end if;
  insert into private.sms_otp_inbox(phone, otp) values (p_phone, p_otp);
end;
$$;

revoke all on function record_log_otp(text, text) from public, anon, authenticated;
grant execute on function record_log_otp(text, text) to service_role;

create or replace function peek_log_otp(p_phone text)
returns text
language plpgsql
stable
security definer
set search_path = public, private, extensions
as $$
declare
  provider text;
  code text;
begin
  provider := coalesce(cfg('sms.provider') #>> '{}', 'log');
  if provider is distinct from 'log' then
    return null;
  end if;
  select i.otp into code
  from private.sms_otp_inbox i
  where i.phone = p_phone
    and i.created_at > now() - interval '10 minutes'
  order by i.created_at desc
  limit 1;
  return code;
end;
$$;

revoke all on function peek_log_otp(text) from public;
grant execute on function peek_log_otp(text) to anon, authenticated, service_role;
