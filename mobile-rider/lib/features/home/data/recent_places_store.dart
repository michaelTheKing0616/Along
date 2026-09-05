import 'dart:convert';

import 'package:along_core/along_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persisted recent/saved destination chips for R-05/R-06.
abstract class RecentPlacesReader {
  Future<List<RecentPlace>> load();
  Future<void> save(List<RecentPlace> places);
  Future<void> add(RecentPlace place);
}

class RecentPlacesStore implements RecentPlacesReader {
  RecentPlacesStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const maxRecents = 8;
  static const _key = 'recent_places_v1';

  final FlutterSecureStorage _storage;

  @override
  Future<List<RecentPlace>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(RecentPlace.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> save(List<RecentPlace> places) async {
    final payload = jsonEncode(places.map((p) => p.toJson()).toList());
    await _storage.write(key: _key, value: payload);
  }

  @override
  Future<void> add(RecentPlace place) async {
    final existing = await load();
    final next = [
      place,
      ...existing.where((p) => p.label != place.label),
    ].take(maxRecents).toList();
    await save(next);
  }
}

class RecentPlace {
  const RecentPlace({
    required this.label,
    required this.location,
    this.kind = 'place',
    this.id,
  });

  final String label;
  final GeoPoint location;
  final String kind;
  final String? id;

  Map<String, dynamic> toJson() => {
        'label': label,
        'lat': location.lat,
        'lng': location.lng,
        'kind': kind,
        'id': id,
      };

  factory RecentPlace.fromJson(Map<String, dynamic> json) => RecentPlace(
        label: json['label'] as String,
        location: GeoPoint(
          lat: (json['lat'] as num).toDouble(),
          lng: (json['lng'] as num).toDouble(),
        ),
        kind: json['kind'] as String? ?? 'place',
        id: json['id'] as String?,
      );
}
