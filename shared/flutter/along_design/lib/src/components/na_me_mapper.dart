import 'package:along_design/src/utils/name_signal.dart';

/// Maps server Na Me tokens to design-system colours/shapes (no hardcoded palette).
NaMeColour naMeColourFromToken(String colorToken) {
  final normalized = colorToken.replaceAll('color.naMe.', '').toLowerCase();
  return switch (normalized) {
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
