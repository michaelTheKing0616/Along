/// Committed brand asset paths under [package:along_design] `assets/`.
library;

/// The one Along brand mark: black-car wordmark, always on pure white.
const String alongLogoBlackSvg = 'assets/logos/main_logo_along_black.svg';

/// Splash branding image (ink wordmark).
const String alongSplashLogo = 'assets/splash/splash_logo.png';

/// 1×1 white seed for splash background colour.
const String alongSplashBackground = 'assets/splash/splash_background.png';

/// Legacy Android launcher icons (`mipmap-*`).
const Map<String, String> androidLegacyLauncherIcons = {
  'mdpi': 'assets/icons/android/mipmap-mdpi/ic_launcher.png',
  'hdpi': 'assets/icons/android/mipmap-hdpi/ic_launcher.png',
  'xhdpi': 'assets/icons/android/mipmap-xhdpi/ic_launcher.png',
  'xxhdpi': 'assets/icons/android/mipmap-xxhdpi/ic_launcher.png',
  'xxxhdpi': 'assets/icons/android/mipmap-xxxhdpi/ic_launcher.png',
};

/// Adaptive Android launcher layers (`drawable-*`).
const Map<String, String> androidAdaptiveForegroundIcons = {
  'mdpi': 'assets/icons/android/drawable-mdpi/ic_launcher_foreground.png',
  'hdpi': 'assets/icons/android/drawable-hdpi/ic_launcher_foreground.png',
  'xhdpi': 'assets/icons/android/drawable-xhdpi/ic_launcher_foreground.png',
  'xxhdpi': 'assets/icons/android/drawable-xxhdpi/ic_launcher_foreground.png',
  'xxxhdpi': 'assets/icons/android/drawable-xxxhdpi/ic_launcher_foreground.png',
};

const Map<String, String> androidAdaptiveBackgroundIcons = {
  'mdpi': 'assets/icons/android/drawable-mdpi/ic_launcher_background.png',
  'hdpi': 'assets/icons/android/drawable-hdpi/ic_launcher_background.png',
  'xhdpi': 'assets/icons/android/drawable-xhdpi/ic_launcher_background.png',
  'xxhdpi': 'assets/icons/android/drawable-xxhdpi/ic_launcher_background.png',
  'xxxhdpi': 'assets/icons/android/drawable-xxxhdpi/ic_launcher_background.png',
};

/// Adaptive icon XML descriptors (Android 8+).
const List<String> androidAdaptiveIconXml = [
  'assets/icons/android/mipmap-anydpi-v26/ic_launcher.xml',
  'assets/icons/android/mipmap-anydpi-v26/ic_launcher_round.xml',
];

/// iOS AppIcon.appiconset entries referenced by Contents.json.
const List<String> iosAppIconAssets = [
  'assets/icons/ios/AppIcon.appiconset/Icon-App-20x20@1x.png',
  'assets/icons/ios/AppIcon.appiconset/Icon-App-20x20@2x.png',
  'assets/icons/ios/AppIcon.appiconset/Icon-App-20x20@3x.png',
  'assets/icons/ios/AppIcon.appiconset/Icon-App-29x29@1x.png',
  'assets/icons/ios/AppIcon.appiconset/Icon-App-29x29@2x.png',
  'assets/icons/ios/AppIcon.appiconset/Icon-App-29x29@3x.png',
  'assets/icons/ios/AppIcon.appiconset/Icon-App-40x40@1x.png',
  'assets/icons/ios/AppIcon.appiconset/Icon-App-40x40@2x.png',
  'assets/icons/ios/AppIcon.appiconset/Icon-App-40x40@3x.png',
  'assets/icons/ios/AppIcon.appiconset/Icon-App-60x60@2x.png',
  'assets/icons/ios/AppIcon.appiconset/Icon-App-60x60@3x.png',
  'assets/icons/ios/AppIcon.appiconset/Icon-App-76x76@1x.png',
  'assets/icons/ios/AppIcon.appiconset/Icon-App-76x76@2x.png',
  'assets/icons/ios/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png',
  'assets/icons/ios/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
  'assets/icons/ios/AppIcon.appiconset/Contents.json',
];

/// Map-filled side-view taxi (Tope's reference), traced to one SVG path in
/// currentColor with hairlines thickened; tint with a ColorFilter so the ink
/// follows the theme.
const String alongTaxiMapSide = 'assets/illustrations/taxi_map_side.svg';
