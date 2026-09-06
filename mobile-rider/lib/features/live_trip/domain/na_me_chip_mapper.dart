import 'package:along_design/along_design.dart';

/// Maps server Na Me tokens to [NaMeColour] / [NaMeShape] (no hardcoded palette).
NaMeColour naMeColourFromToken(String colorToken) {
  final slug = colorToken.split('.').last.toLowerCase();
  return switch (slug) {
    'red' => NaMeColour.red,
    'orange' => NaMeColour.orange,
    'yellow' => NaMeColour.yellow,
    'green' => NaMeColour.green,
    'cyan' => NaMeColour.cyan,
    'blue' => NaMeColour.blue,
    'purple' => NaMeColour.purple,
    'white' => NaMeColour.white,
    'pink' => NaMeColour.red,
    _ => NaMeColour.green,
  };
}

NaMeShape naMeShapeFromToken(String shape) {
  final normalized = shape.toLowerCase();
  return switch (normalized) {
    'circle' => NaMeShape.circle,
    'square' => NaMeShape.square,
    'triangle' => NaMeShape.triangle,
    'diamond' => NaMeShape.diamond,
    'star' => NaMeShape.star,
    'hexagon' => NaMeShape.hexagon,
    _ => NaMeShape.diamond,
  };
}
