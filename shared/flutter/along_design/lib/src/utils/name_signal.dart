import 'package:flutter/material.dart';

import '../tokens.g.dart';

/// Na Me signal colours (doc 05 §6).
enum NaMeColour {
  red,
  orange,
  yellow,
  green,
  cyan,
  blue,
  purple,
  white,
}

/// Na Me signal shapes (doc 05 §6).
enum NaMeShape { circle, square, triangle, diamond, star, hexagon }

extension NaMeColourTokens on NaMeColour {
  Color get color => switch (this) {
        NaMeColour.red => AlongColors.naMeRed,
        NaMeColour.orange => AlongColors.naMeOrange,
        NaMeColour.yellow => AlongColors.naMeYellow,
        NaMeColour.green => AlongColors.naMeGreen,
        NaMeColour.cyan => AlongColors.naMeCyan,
        NaMeColour.blue => AlongColors.naMeBlue,
        NaMeColour.purple => AlongColors.naMePurple,
        NaMeColour.white => AlongColors.naMeWhite,
      };

  String get label => switch (this) {
        NaMeColour.red => 'RED',
        NaMeColour.orange => 'ORANGE',
        NaMeColour.yellow => 'YELLOW',
        NaMeColour.green => 'GREEN',
        NaMeColour.cyan => 'CYAN',
        NaMeColour.blue => 'BLUE',
        NaMeColour.purple => 'PURPLE',
        NaMeColour.white => 'WHITE',
      };
}

extension NaMeShapeTokens on NaMeShape {
  String get label => switch (this) {
        NaMeShape.circle => 'CIRCLE',
        NaMeShape.square => 'SQUARE',
        NaMeShape.triangle => 'TRIANGLE',
        NaMeShape.diamond => 'DIAMOND',
        NaMeShape.star => 'STAR',
        NaMeShape.hexagon => 'HEXAGON',
      };
}
