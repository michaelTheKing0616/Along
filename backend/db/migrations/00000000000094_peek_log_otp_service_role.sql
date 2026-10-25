-- peek_log_otp returns live OTP codes; anon/authenticated must never call it.
-- Restrict to service_role and make both log-mode helpers fail closed: a missing
-- sms.provider setting no longer means 'log' (dev keeps the 0021 default 'log').

create or replace function record_log_otp(p_phone text, p_otp text)
returns void
language plpgsql
security definer
set search_path = public, private, extensions
as $$
begin
  if (cfg('sms.provider') #>> '{}') is distinct from 'log' then
    return;
  end if;
  insert into private.sms_otp_inbox(phone, otp) values (p_phone, p_otp);
end;
$$;

create or replace function peek_log_otp(p_phone text)
returns text
language plpgsql
stable
security definer
set search_path = public, private, extensions
as $$
declare
  code text;
begin
  if (cfg('sms.provider') #>> '{}') is distinct from 'log' then
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

revoke all on function record_log_otp(text, text) from public, anon, authenticated;
grant execute on function record_log_otp(text, text) to service_role;
revoke all on function peek_log_otp(text) from public, anon, authenticated;
grant execute on function peek_log_otp(text) to service_role;
