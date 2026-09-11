import 'package:flutter/material.dart';

import '../../theme/theme.dart';

void showAppToast(
  BuildContext context, {
  required String message,
  IconData? icon,
  Color? iconColor,
}) {
  final AppColors colors = context.colors;
  final AppDimens dimens = context.dimens;

  ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.fromLTRB(
          dimens.space4,
          0,
          dimens.space4,
          dimens.space3,
        ),
        padding: EdgeInsets.zero,
        content: _ToastContent(
          message: message,
          icon: icon,
          iconColor: iconColor ?? colors.textSecondary,
        ),
      ),
    );
}

class _ToastContent extends StatelessWidget {
  const _ToastContent({
    required this.message,
    required this.icon,
    required this.iconColor,
  });

  static const double _height = 46;

  final String message;
  final IconData? icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final IconData? icon = this.icon;

    return Container(
      height: _height,
      padding: EdgeInsets.symmetric(horizontal: dimens.space4),
      decoration: BoxDecoration(
        color: colors.surfaceOverlay,
        borderRadius: BorderRadius.circular(dimens.radiusLg),
        border: Border.all(
          color: colors.borderSubtle,
          width: dimens.borderHairline,
        ),
      ),
      child: Row(
        spacing: dimens.space2,
        children: [
          if (icon != null) Icon(icon, size: dimens.iconSm, color: iconColor),
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bold13.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
