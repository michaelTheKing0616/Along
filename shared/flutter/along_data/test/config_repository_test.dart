import 'package:along_data/along_data.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGateway implements AlongSupabase {
  _FakeGateway(this.rows);

  final List<Map<String, dynamic>> rows;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Map<String, dynamic>>> selectRows(
    String table, {
    Map<String, Object?> filters = const {},
    String? inColumn,
    List<Object?>? inValues,
  }) async =>
      rows.where((row) => filters['key'] == null || row['key'] == filters['key']).toList();
}

void main() {
  test('ConfigRepository resolves city override over global', () async {
    final repo = ConfigRepository(
      _FakeGateway([
        {
          'key': 'graph.snap_radius_m',
          'scope_type': 'global',
          'scope_id': '*',
          'value': '60',
        },
        {
          'key': 'graph.snap_radius_m',
          'scope_type': 'city',
          'scope_id': 'city-1',
          'value': '40',
        },
      ]),
    );

    expect(
      await repo.configNum('graph.snap_radius_m', cityId: 'city-1'),
      40,
    );
  });
}
