import 'package:along_core/src/perf/app_startup_metrics.dart';
import 'package:test/test.dart';

void main() {
  test('coldStartMs aggregates process start to bootstrap complete', () {
    final metrics = AppStartupMetrics.instance..resetForTest();
    metrics
      ..markProcessStart()
      ..markBindingReady()
      ..markBootstrapComplete();

    expect(metrics.coldStartMs, isNotNull);
    expect(metrics.coldStartMs!, greaterThanOrEqualTo(0));
    expect(metrics.passesColdStartBudget, isTrue);
  });

  test('passesColdStartBudget respects 2500 ms gate', () {
    expect(AppStartupMetrics.coldStartBudgetMs, 2500);
  });
}
