-- private.sms_otp_inbox (0081) shipped without RLS. Enable it with no policies:
-- only the security-definer record_log_otp / peek_log_otp functions touch it.
alter table private.sms_otp_inbox enable row level security;
revoke all on table private.sms_otp_inbox from public, anon, authenticated;
