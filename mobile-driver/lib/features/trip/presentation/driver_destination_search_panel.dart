import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/home/presentation/home_controller.dart';

class DriverDestinationPick {
  const DriverDestinationPick({
    required this.name,
    required this.location,
    this.stageId,
  });

  final String name;
  final GeoPoint location;
  final String? stageId;

  factory DriverDestinationPick.fromPlace(PlaceResult place) =>
      DriverDestinationPick(
        name: place.name,
        location: place.location,
        stageId: place.kind == 'stage' ? place.id : null,
      );

  Map<String, dynamic> toNewAlightPayload() => {
        if (stageId != null) 'stage_id': stageId,
        'lat': location.lat,
        'lng': location.lng,
        'name': name,
      };
}

/// Driver-side destination search for D-17 (pattern from rider R-06).
class DriverDestinationSearchPanel extends ConsumerStatefulWidget {
  const DriverDestinationSearchPanel({
    super.key,
    required this.onDestinationSelected,
    this.hint,
  });

  final ValueChanged<DriverDestinationPick> onDestinationSelected;
  final String? hint;

  @override
  ConsumerState<DriverDestinationSearchPanel> createState() =>
      _DriverDestinationSearchPanelState();
}

class _DriverDestinationSearchPanelState
    extends ConsumerState<DriverDestinationSearchPanel> {
  late final TextEditingController _controller;
  List<PlaceResult> _results = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _loading = true);
    try {
      final home = ref.read(driverHomeControllerProvider);
      final location = home.userLocation ?? const GeoPoint(lat: 9.05, lng: 7.49);
      final places = ref.read(placesRepositoryProvider);
      final cityId = home.cityId ?? await places.cityForLocation(location);
      if (cityId == null) {
        setState(() => _results = const []);
        return;
      }
      final results = await places.searchPlaces(
        query: query,
        near: location,
        cityId: cityId,
        limit: 8,
      );
      if (mounted) setState(() => _results = results);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SearchField(
          key: const Key('driver_extend_search_field'),
          variant: SearchFieldVariant.full,
          hint: widget.hint ?? 'Where to?',
          controller: _controller,
          onChanged: _search,
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        for (final place in _results)
          ListTile(
            key: Key('driver_extend_place_${place.name}'),
            title: Text(place.name),
            subtitle: Text(place.area),
            onTap: () => widget.onDestinationSelected(
              DriverDestinationPick.fromPlace(place),
            ),
          ),
      ],
    );
  }
}
