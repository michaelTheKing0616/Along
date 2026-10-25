import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/config/app_config.dart';

AppConfig _cfg(String? url) => AppConfig(
  flavor: 'dev',
  supabaseUrl: 'https://x.supabase.co',
  supabaseAnonKey: 'k',
  supportUrl: url,
);

void main() {
  test('support link is empty-safe and free-scheme only', () {
    expect(_cfg(null).supportUri, isNull);
    expect(_cfg('  ').supportUri, isNull);
    expect(_cfg('javascript:alert(1)').supportUri, isNull);
    expect(_cfg('https://wa.me/2348000000000').supportUri?.host, 'wa.me');
    expect(_cfg('tel:+2348000000000').supportUri?.scheme, 'tel');
    expect(_cfg('mailto:help@example.com').supportUri?.scheme, 'mailto');
  });
}
