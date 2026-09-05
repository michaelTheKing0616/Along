import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens.g.dart';

/// Search field layout variants (doc 05 §9 `SearchField`).
enum SearchFieldVariant { home, full }

/// Destination search input — 56 dp high with leading search icon.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.variant = SearchFieldVariant.home,
    this.hint = 'Where to?',
    this.controller,
    this.onChanged,
    this.onRecentsTap,
  });

  final SearchFieldVariant variant;
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onRecentsTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: hint,
      child: Container(
        height: AlongSpace.sizeListRowMin,
        decoration: BoxDecoration(
          color: variant == SearchFieldVariant.home
              ? AlongColors.surface100
              : AlongColors.surface0,
          borderRadius: BorderRadius.circular(AlongRadius.sm.x),
          border: variant == SearchFieldVariant.full
              ? Border.all(color: AlongColors.ink100)
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AlongSpace.s12),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: AlongColors.ink500),
            const SizedBox(width: AlongSpace.s8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: AlongText.body,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AlongText.body.copyWith(color: AlongColors.ink500),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (variant == SearchFieldVariant.home && onRecentsTap != null)
              IconButton(
                onPressed: onRecentsTap,
                icon: Icon(Icons.history_rounded, color: AlongColors.ink700),
                tooltip: 'Recent searches',
              ),
          ],
        ),
      ),
    );
  }
}

/// Phone number field with +234 prefix (doc 05 §9 `PhoneField`).
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    this.controller,
    this.errorText,
    this.countryCode = '+234',
    this.onChanged,
  });

  final TextEditingController? controller;
  final String? errorText;
  final String countryCode;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: AlongSpace.sizeListRowMin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AlongRadius.sm.x),
            border: Border.all(
              color: hasError ? AlongColors.semanticDangerFill : AlongColors.ink100,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AlongSpace.s12),
          child: Row(
            children: [
              Text(countryCode, style: AlongText.bodyStrong),
              Container(
                width: 1,
                height: AlongSpace.s24,
                margin: const EdgeInsets.symmetric(horizontal: AlongSpace.s12),
                color: AlongColors.ink100,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AlongText.body,
                  decoration: InputDecoration(
                    hintText: '801 234 5678',
                    hintStyle: AlongText.body.copyWith(color: AlongColors.ink500),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AlongSpace.s4),
          Text(
            errorText!,
            style: AlongText.caption.copyWith(color: AlongColors.semanticDanger),
          ),
        ],
      ],
    );
  }
}

/// Six-digit OTP input (doc 05 §9 `OtpField`).
class OtpField extends StatelessWidget {
  const OtpField({
    super.key,
    this.controller,
    this.errorText,
    this.length = 6,
    this.onChanged,
  });

  final TextEditingController? controller;
  final String? errorText;
  final int length;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: AlongSpace.sizeListRowMin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AlongRadius.sm.x),
            border: Border.all(
              color: hasError ? AlongColors.semanticDangerFill : AlongColors.ink100,
            ),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: length,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AlongText.heading2.copyWith(letterSpacing: 8),
            decoration: InputDecoration(
              hintText: '·' * length,
              counterText: '',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AlongSpace.s16,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AlongSpace.s4),
          Text(
            errorText!,
            style: AlongText.caption.copyWith(color: AlongColors.semanticDanger),
          ),
        ],
      ],
    );
  }
}
