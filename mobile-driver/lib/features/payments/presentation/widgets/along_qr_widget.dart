import 'dart:io' show Platform;

import 'package:along_design/along_design.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Static or dynamic Along QR with error-correction H (doc 14 §2, D-25/D-26).
class AlongQrWidget extends StatelessWidget {
  const AlongQrWidget({
    super.key,
    required this.data,
    this.size = 240,
    this.plate,
    this.renderPixels,
  });

  final String data;
  final double size;
  final String? plate;

  /// When null, paints in app runtime and stubs in `flutter test`.
  final bool? renderPixels;

  bool get _renderPixels {
    if (renderPixels != null) return renderPixels!;
    return !_isFlutterTest;
  }

  static bool get _isFlutterTest {
    if (kIsWeb) return false;
    return Platform.environment.containsKey('FLUTTER_TEST');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AlongSpace.s12),
          clipBehavior: Clip.antiAlias,
          decoration: AlongCraft.fill(
            AlongColors.brandYellow,
            corner: AlongRadius.card.x,
            side: const BorderSide(color: AlongColors.ink900, width: 2),
          ),
          child: _renderPixels
              ? QrImageView(
                  key: const Key('along_qr_widget'),
                  data: data,
                  version: QrVersions.auto,
                  size: size,
                  backgroundColor: AlongColors.brandYellow,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AlongColors.ink900,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AlongColors.ink900,
                  ),
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                )
              : SizedBox(
                  key: const Key('along_qr_widget'),
                  width: size,
                  height: size,
                ),
        ),
        if (plate != null && plate!.isNotEmpty) ...[
          const SizedBox(height: AlongSpace.s8),
          Text(
            plate!,
            style: AlongText.numericL.copyWith(color: AlongColors.ink900),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
