-- pgTAP: TS-OTP-01 — private.sms_otp_inbox is service-only (RLS) and the
-- log-mode OTP helpers round-trip only while sms.provider = 'log' (0081, 0092).
create extension if not exists pgtap;

begin;
select plan(6);

select ok(
  (select c.relrowsecurity
   from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'private' and c.relname = 'sms_otp_inbox'),
  'TS-OTP-01: private.sms_otp_inbox has RLS enabled'
);

select ok(
  not has_table_privilege('authenticated', 'private.sms_otp_inbox', 'select'),
  'TS-OTP-01: authenticated cannot read the inbox directly'
);

select ok(
  not has_table_privilege('anon', 'private.sms_otp_inbox', 'select'),
  'TS-OTP-01: anon cannot read the inbox directly'
);

select lives_ok(
  $$ select record_log_otp('+2348000009001', '123456') $$,
  'TS-OTP-01: record_log_otp stores a code in log mode'
);

select is(
  peek_log_otp('+2348000009001'),
  '123456',
  'TS-OTP-01: peek_log_otp returns the latest code in log mode'
);

update app_config set value = '"termii"'
where key = 'sms.provider' and scope_type = 'global';

select is(
  peek_log_otp('+2348000009001'),
  null,
  'TS-OTP-01: peek_log_otp returns nothing outside log mode'
);

select * from finish();
rollback;
