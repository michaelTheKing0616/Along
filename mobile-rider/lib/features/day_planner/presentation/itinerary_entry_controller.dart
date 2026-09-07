import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/trip_options/domain/trip_plan_session.dart';

enum ItineraryEntryMode { structured, naturalLanguage }

class StructuredStopDraft {
  StructuredStopDraft({
    required this.id,
    this.label = '',
    this.location,
  });

  final String id;
  String label;
  GeoPoint? location;
}

class ItineraryEntryState {
  const ItineraryEntryState({
    this.mode = ItineraryEntryMode.structured,
    this.stops = const [],
    this.nlText = '',
    this.proposal = const [],
    this.needsConfirmation = false,
    this.isParsing = false,
    this.isSaving = false,
    this.errorMessage,
    this.load = const LoadFlagState(),
    this.parseInvoked = false,
    this.createInvoked = false,
    this.existingItineraryId,
    this.nextSequence = 1,
    this.addInvoked = false,
  });

  final ItineraryEntryMode mode;
  final List<StructuredStopDraft> stops;
  final String nlText;
  final List<ParseItineraryProposalItem> proposal;
  final bool needsConfirmation;
  final bool isParsing;
  final bool isSaving;
  final String? errorMessage;
  final LoadFlagState load;
  final bool parseInvoked;
  final bool createInvoked;
  final String? existingItineraryId;
  final int nextSequence;
  final bool addInvoked;

  bool get isAddToExisting => existingItineraryId != null;

  ItineraryEntryState copyWith({
    ItineraryEntryMode? mode,
    List<StructuredStopDraft>? stops,
    String? nlText,
    List<ParseItineraryProposalItem>? proposal,
    bool? needsConfirmation,
    bool? isParsing,
    bool? isSaving,
    String? errorMessage,
    LoadFlagState? load,
    bool? parseInvoked,
    bool? createInvoked,
    String? existingItineraryId,
    int? nextSequence,
    bool? addInvoked,
    bool clearProposal = false,
    bool clearError = false,
  }) {
    return ItineraryEntryState(
      mode: mode ?? this.mode,
      stops: stops ?? this.stops,
      nlText: nlText ?? this.nlText,
      proposal: clearProposal ? const [] : (proposal ?? this.proposal),
      needsConfirmation: needsConfirmation ?? this.needsConfirmation,
      isParsing: isParsing ?? this.isParsing,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      load: load ?? this.load,
      parseInvoked: parseInvoked ?? this.parseInvoked,
      createInvoked: createInvoked ?? this.createInvoked,
      existingItineraryId: existingItineraryId ?? this.existingItineraryId,
      nextSequence: nextSequence ?? this.nextSequence,
      addInvoked: addInvoked ?? this.addInvoked,
    );
  }
}

final itineraryEntryControllerProvider =
    NotifierProvider<ItineraryEntryController, ItineraryEntryState>(
  ItineraryEntryController.new,
);

class ItineraryEntryController extends Notifier<ItineraryEntryState> {
  @override
  ItineraryEntryState build() {
    return ItineraryEntryState(
      stops: [
        StructuredStopDraft(id: 'stop-1'),
        StructuredStopDraft(id: 'stop-2'),
      ],
    );
  }

  void setMode(ItineraryEntryMode mode) {
    state = state.copyWith(mode: mode, clearProposal: true, clearError: true);
  }

  void updateLoad(LoadFlagState load) {
    state = state.copyWith(load: load);
  }

  /// R-20 "Add stop" — append to an active itinerary via update_itinerary_stops.
  Future<void> configureForExistingItinerary(String itineraryId) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final repo = ref.read(itineraryRepositoryProvider);
      final view = await repo.itineraryState(itineraryId);
      final maxSequence = view.stops.isEmpty
          ? 0
          : view.stops.map((s) => s.sequence).reduce((a, b) => a > b ? a : b);
      state = state.copyWith(
        existingItineraryId: itineraryId,
        nextSequence: maxSequence + 1,
        stops: [StructuredStopDraft(id: 'stop-add-1')],
        isSaving: false,
      );
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }

  void setNlText(String text) {
    state = state.copyWith(nlText: text);
  }

  void addStructuredStop() {
    state = state.copyWith(
      stops: [
        ...state.stops,
        StructuredStopDraft(id: 'stop-${state.stops.length + 1}'),
      ],
    );
  }

  void updateStopLabel(int index, String label) {
    final stops = [...state.stops];
    if (index < 0 || index >= stops.length) return;
    stops[index].label = label;
    state = state.copyWith(stops: stops);
  }

  void updateStopLocation(int index, GeoPoint location) {
    final stops = [...state.stops];
    if (index < 0 || index >= stops.length) return;
    stops[index].location = location;
    state = state.copyWith(stops: stops);
  }

  void reorderStructuredStop(int oldIndex, int newIndex) {
    final stops = [...state.stops];
    if (oldIndex < newIndex) newIndex -= 1;
    final item = stops.removeAt(oldIndex);
    stops.insert(newIndex, item);
    state = state.copyWith(stops: stops);
  }

  void removeStructuredStop(int index) {
    final stops = [...state.stops];
    if (index < 0 || index >= stops.length) return;
    stops.removeAt(index);
    state = state.copyWith(stops: stops);
  }

  void applyProposalToStructured() {
    final proposal = state.proposal;
    if (proposal.isEmpty) return;
    state = state.copyWith(
      mode: ItineraryEntryMode.structured,
      stops: proposal
          .map(
            (item) => StructuredStopDraft(
              id: 'parsed-${item.sequence}',
              label: item.resolvedLabel ?? item.destinationDescription,
              location: item.resolvedLocation,
            ),
          )
          .toList(growable: false),
      clearProposal: true,
    );
  }

  /// Calls parse-itinerary only — never writes (§5.3).
  Future<void> parseNaturalLanguage({required String cityId}) async {
    final text = state.nlText.trim();
    if (text.length < 3) return;

    state = state.copyWith(isParsing: true, clearError: true, parseInvoked: true);
    try {
      final repo = ref.read(itineraryRepositoryProvider);
      final result = await repo.parseItinerary(text: text, cityId: cityId);
      state = state.copyWith(
        proposal: result.proposal,
        needsConfirmation: result.needsConfirmation,
        isParsing: false,
      );
    } catch (e) {
      state = state.copyWith(isParsing: false, errorMessage: e.toString());
    }
  }

  /// Confirmed write — only after "Looks right" tap (new itinerary).
  Future<ItineraryStateView?> confirmAndCreate({required String cityId}) async {
    if (state.isAddToExisting) {
      return confirmAndAddStops();
    }

    state = state.copyWith(isSaving: true, clearError: true, createInvoked: true);
    try {
      final stopsPayload = _buildStopsPayload();
      if (stopsPayload.isEmpty) {
        state = state.copyWith(isSaving: false, errorMessage: 'No stops to save');
        return null;
      }

      final repo = ref.read(itineraryRepositoryProvider);
      final load = state.load.flagged
          ? {
              'flagged': true,
              if (state.load.size != null) 'size': state.load.size,
              if (state.load.note != null) 'note': state.load.note,
            }
          : {'flagged': false};

      final view = await repo.createItinerary(stops: stopsPayload, load: load);
      state = state.copyWith(isSaving: false, clearProposal: true);
      return view;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Append stops to an active itinerary (R-20 Add stop path).
  Future<ItineraryStateView?> confirmAndAddStops() async {
    final itineraryId = state.existingItineraryId;
    if (itineraryId == null) return null;

    state = state.copyWith(isSaving: true, clearError: true, addInvoked: true);
    try {
      final stopsPayload = _buildStopsPayload();
      if (stopsPayload.isEmpty) {
        state = state.copyWith(isSaving: false, errorMessage: 'No stops to save');
        return null;
      }

      final ops = <Map<String, dynamic>>[];
      for (var i = 0; i < stopsPayload.length; i++) {
        final stop = stopsPayload[i];
        ops.add({
          'op': 'add',
          'sequence': state.nextSequence + i,
          'destination_description': stop['destination_description'],
          if (stop.containsKey('location')) 'location': stop['location'],
        });
      }

      final repo = ref.read(itineraryRepositoryProvider);
      final view = await repo.updateItineraryStops(
        itineraryId: itineraryId,
        ops: ops,
      );
      state = state.copyWith(isSaving: false, clearProposal: true);
      return view;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return null;
    }
  }

  List<Map<String, dynamic>> _buildStopsPayload() {
    if (state.mode == ItineraryEntryMode.naturalLanguage &&
        state.proposal.isNotEmpty) {
      return state.proposal
          .map(
            (item) => {
              'sequence': item.sequence,
              'destination_description':
                  item.resolvedLabel ?? item.destinationDescription,
              if (item.resolvedLocation != null)
                'location': {
                  'lat': item.resolvedLocation!.lat,
                  'lng': item.resolvedLocation!.lng,
                },
            },
          )
          .toList(growable: false);
    }

    final valid = state.stops.where((s) => s.label.trim().isNotEmpty).toList();
    return [
      for (var i = 0; i < valid.length; i++)
        {
          'sequence': i + 1,
          'destination_description': valid[i].label.trim(),
          if (valid[i].location != null)
            'location': {
              'lat': valid[i].location!.lat,
              'lng': valid[i].location!.lng,
            },
        },
    ];
  }
}
