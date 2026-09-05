import 'package:mobile_rider/features/home/data/recent_places_store.dart';

/// In-memory recents for widget/unit tests (no secure storage).
class FakeRecentPlacesStore implements RecentPlacesReader {
  FakeRecentPlacesStore({this.places = const []});

  List<RecentPlace> places;

  @override
  Future<List<RecentPlace>> load() async => List.unmodifiable(places);

  @override
  Future<void> save(List<RecentPlace> next) async {
    places = List.of(next);
  }

  @override
  Future<void> add(RecentPlace place) async {
    places = [
      place,
      ...places.where((p) => p.label != place.label),
    ].take(RecentPlacesStore.maxRecents).toList();
  }
}
