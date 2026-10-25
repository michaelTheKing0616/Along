-- pgTAP: TS-OTP-02 — peek_log_otp is service_role only and fails closed when
-- sms.provider is unset (0094).
create extension if not exists pgtap;

begin;
select plan(8);

select ok(not has_function_privilege('anon', 'public.peek_log_otp(text)', 'execute'),
  'TS-OTP-02: anon has no execute on peek_log_otp');
select ok(not has_function_privilege('authenticated', 'public.peek_log_otp(text)', 'execute'),
  'TS-OTP-02: authenticated has no execute on peek_log_otp');
select ok(not exists (
    select 1 from pg_proc p, aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
    where p.oid = 'public.peek_log_otp(text)'::regprocedure and a.grantee = 0 and a.privilege_type = 'EXECUTE'),
  'TS-OTP-02: PUBLIC has no execute on peek_log_otp');
select ok(has_function_privilege('service_role', 'public.peek_log_otp(text)', 'execute'),
  'TS-OTP-02: service_role can execute peek_log_otp');

set local role anon;
select throws_ok($$ select peek_log_otp('+2348000009002') $$, '42501', null,
  'TS-OTP-02: anon call is denied');
reset role;

set local role authenticated;
select throws_ok($$ select peek_log_otp('+2348000009002') $$, '42501', null,
  'TS-OTP-02: authenticated call is denied');
reset role;

select record_log_otp('+2348000009002', '654321');
delete from app_config where key = 'sms.provider';

select is(peek_log_otp('+2348000009002'), null,
  'TS-OTP-02: unset sms.provider does not default to log mode (peek)');

select record_log_otp('+2348000009003', '111111');
select is((select count(*)::int from private.sms_otp_inbox where phone = '+2348000009003'), 0,
  'TS-OTP-02: unset sms.provider does not default to log mode (record)');

select * from finish();
rollback;
