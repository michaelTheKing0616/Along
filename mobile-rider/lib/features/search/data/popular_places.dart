import 'package:along_core/along_core.dart';
import 'package:mobile_rider/features/home/data/recent_places_store.dart';

/// Well-known destinations per city, shown under Recents so a new rider
/// still has one-tap starts. Keyed by lowercase city name.
const Map<String, List<PopularPlace>> popularPlacesByCity = {
  'abuja': [
    PopularPlace(
      'Wuse Market',
      'Wuse',
      'market',
      GeoPoint(lat: 9.0645, lng: 7.4659),
    ),
    PopularPlace(
      'Area 1 Park',
      'Garki',
      'park',
      GeoPoint(lat: 9.0329, lng: 7.4781),
    ),
    PopularPlace(
      'Berger Junction',
      'Wuse II',
      'stage',
      GeoPoint(lat: 9.0702, lng: 7.4632),
    ),
    PopularPlace(
      'Jabi Lake Mall',
      'Jabi',
      'market',
      GeoPoint(lat: 9.0726, lng: 7.4218),
    ),
  ],
};

class PopularPlace {
  const PopularPlace(this.name, this.area, this.kind, this.location);

  final String name;
  final String area;
  final String kind;
  final GeoPoint location;

  RecentPlace toRecent() =>
      RecentPlace(label: name, location: location, kind: kind);
}
