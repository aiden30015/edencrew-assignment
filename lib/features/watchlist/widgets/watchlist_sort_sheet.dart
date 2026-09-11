import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../models/watchlist_sort.dart';

Future<WatchlistSort?> showWatchlistSortSheet(
  BuildContext context, {
  required WatchlistSort selected,
}) {
  final AppDimens dimens = context.dimens;

  return showModalBottomSheet<WatchlistSort>(
    context: context,
    backgroundColor: context.colors.surfaceOverlay,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(dimens.radiusLg),
      ),
    ),
    builder: (BuildContext context) => _WatchlistSortSheet(selected: selected),
  );
}

class _WatchlistSortSheet extends StatelessWidget {
  const _WatchlistSortSheet({required this.selected});

  final WatchlistSort selected;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(bottom: dimens.space2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dimens.space6,
              vertical: dimens.space5,
            ),
            child: Text(
              '정렬',
              style: AppTypography.bold19.copyWith(color: colors.textPrimary),
            ),
          ),
          for (final WatchlistSort sort in WatchlistSort.values)
            _SortOption(
              label: sort.label,
              isSelected: sort == selected,
              onTap: () => Navigator.of(context).pop(sort),
            ),
        ],
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: dimens.rowMinHeight,
        padding: EdgeInsets.symmetric(horizontal: dimens.space6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.medium15.copyWith(
                  color: isSelected ? colors.textPrimary : colors.textSecondary,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, size: 24, color: colors.textPrimary),
          ],
        ),
      ),
    );
  }
}
