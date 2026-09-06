/// Rider wayfinding presentation preference (§4.11, doc 06 R-19).
enum WayfindingMode {
  text,
  map,
  audio;

  static WayfindingMode tryParse(String? raw) => switch (raw) {
        'map' => WayfindingMode.map,
        'audio' => WayfindingMode.audio,
        _ => WayfindingMode.text,
      };

  String get wireValue => switch (this) {
        WayfindingMode.text => 'text',
        WayfindingMode.map => 'map',
        WayfindingMode.audio => 'audio',
      };
}
