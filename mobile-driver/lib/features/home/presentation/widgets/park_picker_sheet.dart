import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/features/home/presentation/home_controller.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

/// D-09 Park picker — nearby parks within configured radius (doc 06).
class ParkPickerSheet extends ConsumerWidget {
  const ParkPickerSheet({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(parkPickerControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AlongSpace.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.homeParkPickerTitle, style: AlongText.heading2),
            const SizedBox(height: AlongSpace.s16),
            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (state.parks.isEmpty)
              Text(l10n.homeParkPickerEmpty, style: AlongText.body)
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.parks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final park = state.parks[index];
                    final distanceM = park.distanceM.round();
                    return ListTile(
                      title: Text(park.name),
                      subtitle: Text(l10n.homeParkDistance(distanceM)),
                      onTap: park.id == null
                          ? null
                          : () async {
                              await ref
                                  .read(driverHomeControllerProvider.notifier)
                                  .selectPark(
                                    SelectedPark(
                                      id: park.id!,
                                      name: park.name,
                                    ),
                                  );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                    );
                  },
                ),
              ),
            const SizedBox(height: AlongSpace.s8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.homeParkSomewhereElse),
            ),
          ],
        ),
      ),
    );
  }
}
