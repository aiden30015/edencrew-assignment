import 'package:flutter/material.dart';

import '../../../shared/widgets/app_header.dart';
import '../../../theme/theme.dart';
import '../models/watchlist_sort.dart';

class WatchlistAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WatchlistAppBar({
    super.key,
    required this.sort,
    required this.reversed,
    required this.onSortTap,
    required this.onRefresh,
  });

  static const double _height = 52;

  final WatchlistSort sort;

  final bool reversed;
  final VoidCallback onSortTap;
  final VoidCallback onRefresh;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return AppHeader(
      height: _height,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '관심',
              style: AppTypography.bold19.copyWith(color: colors.textPrimary),
            ),
          ),
          InkWell(
            onTap: onSortTap,
            borderRadius: BorderRadius.circular(dimens.radiusSm),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: dimens.space1),
              child: Row(
                children: [
                  Text(
                    sort.label,
                    style: AppTypography.bold13.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  Icon(
                    reversed ? Icons.arrow_upward : Icons.arrow_downward,
                    size: dimens.iconMd,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: dimens.space4),
          HeaderIconButton(
            icon: Icons.sync,
            color: colors.textSecondary,
            onTap: onRefresh,
            tooltip: '새로고침',
          ),
        ],
      ),
    );
  }
}
