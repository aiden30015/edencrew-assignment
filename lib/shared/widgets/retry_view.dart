import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class RetryView extends StatelessWidget {
  const RetryView({
    super.key,
    required this.message,
    required this.onRetry,
    this.showIcon = true,
  });

  final String message;
  final VoidCallback onRetry;

  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: dimens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (showIcon) ...<Widget>[
              Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: colors.textTertiary,
              ),
              SizedBox(height: dimens.space3),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.regular13.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: dimens.space2),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: colors.accentDefault,
                backgroundColor: colors.accentBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(dimens.radiusMd),
                ),
              ),
              child: const Text('다시 시도', style: AppTypography.bold13),
            ),
          ],
        ),
      ),
    );
  }
}
