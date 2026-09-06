import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/payments/data/payments_providers.dart';
import 'package:mobile_driver/features/payments/domain/qr_scanner_port.dart';
import 'package:mobile_driver/features/payments/domain/share_image_port.dart';

class MyQrState {
  const MyQrState({
    this.profile,
    this.stickerRequests = const [],
    this.digitalEnabled = false,
    this.isLoading = true,
    this.isBusy = false,
    this.verifyMessage,
    this.errorMessage,
  });

  final DriverQrProfile? profile;
  final List<QrStickerRequest> stickerRequests;
  final bool digitalEnabled;
  final bool isLoading;
  final bool isBusy;
  final String? verifyMessage;
  final String? errorMessage;

  bool get showPayoutPrompt => profile != null && !profile!.hasSubaccount;

  bool get digitalPaused =>
      profile != null && profile!.hasSubaccount && !profile!.acceptsDigital;

  MyQrState copyWith({
    DriverQrProfile? profile,
    List<QrStickerRequest>? stickerRequests,
    bool? digitalEnabled,
    bool? isLoading,
    bool? isBusy,
    String? verifyMessage,
    String? errorMessage,
    bool clearVerify = false,
    bool clearError = false,
  }) {
    return MyQrState(
      profile: profile ?? this.profile,
      stickerRequests: stickerRequests ?? this.stickerRequests,
      digitalEnabled: digitalEnabled ?? this.digitalEnabled,
      isLoading: isLoading ?? this.isLoading,
      isBusy: isBusy ?? this.isBusy,
      verifyMessage: clearVerify ? null : (verifyMessage ?? this.verifyMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final myQrControllerProvider =
    NotifierProvider<MyQrController, MyQrState>(MyQrController.new);

final qrScannerProvider = Provider<QrScannerPort>((ref) => StubQrScanner());

final shareImageProvider = Provider<ShareImagePort>((ref) => StubShareImagePort());

class MyQrController extends Notifier<MyQrState> {
  @override
  MyQrState build() {
    Future.microtask(refresh);
    return const MyQrState();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userId = ref.read(alongSupabaseProvider).currentUser?.id;
      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final digitalEnabled =
          await ref.read(digitalPaymentsEnabledProvider.future);
      final repo = ref.read(driverQrRepositoryProvider);
      final profile = await repo.fetchProfile(userId);
      final stickers = await repo.fetchStickerRequests(userId);
      state = MyQrState(
        profile: profile,
        stickerRequests: stickers,
        digitalEnabled: digitalEnabled,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'load_failed',
      );
    }
  }

  String? staticQrUrl() {
    final profile = state.profile;
    if (profile == null || profile.driverCode == null) return null;
    return QrUrlBuilder.staticDriverUrl(
      driverCode: profile.driverCode!,
      publicOrigin: profile.publicOrigin,
    );
  }

  Future<void> shareImage() async {
    final profile = state.profile;
    final url = staticQrUrl();
    if (profile == null || url == null) return;
    await ref.read(shareImageProvider).shareQrImage(
          driverCode: profile.driverCode!,
          plate: profile.plate,
          payloadUrl: url,
        );
  }

  Future<void> orderSticker() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final request =
          await ref.read(driverQrRepositoryProvider).requestSticker();
      state = state.copyWith(
        isBusy: false,
        stickerRequests: [request, ...state.stickerRequests],
      );
    } catch (_) {
      state = state.copyWith(isBusy: false, errorMessage: 'sticker_failed');
    }
  }

  Future<void> verifySticker(QrScannerPort scanner) async {
    final profile = state.profile;
    final code = profile?.driverCode;
    if (code == null) return;

    state = state.copyWith(isBusy: true, clearVerify: true, clearError: true);
    try {
      await scanner.start();
      final payload = await scanner.scans.first.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('scan timeout'),
      );
      await scanner.stop();

      final scannedCode = QrPayloadParser.parse(payload);
      if (scannedCode == null) {
        state = state.copyWith(isBusy: false, verifyMessage: 'invalid');
        return;
      }

      final resolved = await ref.read(driverQrRepositoryProvider).resolveQr(
            driverCode: scannedCode,
          );
      if (scannedCode == code &&
          resolved.driver?.plate == profile!.plate &&
          resolved.driver?.active == true) {
        state = state.copyWith(isBusy: false, verifyMessage: 'match');
      } else {
        state = state.copyWith(isBusy: false, verifyMessage: 'mismatch');
      }
    } on TimeoutException {
      await scanner.stop();
      state = state.copyWith(isBusy: false, verifyMessage: 'timeout');
    } catch (_) {
      await scanner.stop();
      state = state.copyWith(isBusy: false, verifyMessage: 'error');
    }
  }

  Future<void> toggleAcceptsDigital(bool enabled) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final accepts =
          await ref.read(driverQrRepositoryProvider).setAcceptsDigital(enabled);
      final profile = state.profile;
      if (profile != null) {
        state = state.copyWith(
          isBusy: false,
          profile: DriverQrProfile(
            driverCode: profile.driverCode,
            plate: profile.plate,
            acceptsDigital: accepts,
            hasSubaccount: profile.hasSubaccount,
            publicOrigin: profile.publicOrigin,
          ),
        );
      }
    } catch (_) {
      state = state.copyWith(isBusy: false, errorMessage: 'pause_failed');
    }
  }

  Future<void> rotateCode() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final newCode =
          await ref.read(driverQrRepositoryProvider).rotateDriverCode();
      final profile = state.profile;
      if (profile != null) {
        state = state.copyWith(
          isBusy: false,
          profile: DriverQrProfile(
            driverCode: newCode,
            plate: profile.plate,
            acceptsDigital: profile.acceptsDigital,
            hasSubaccount: profile.hasSubaccount,
            publicOrigin: profile.publicOrigin,
          ),
        );
      }
      await refresh();
    } catch (_) {
      state = state.copyWith(isBusy: false, errorMessage: 'rotate_failed');
    }
  }
}
