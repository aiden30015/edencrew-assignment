import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../models/watchlist_item.dart';
import 'watchlist_row.dart';

class WatchlistList extends StatelessWidget {
  const WatchlistList({
    super.key,
    required this.items,
    required this.hasError,
    required this.refreshIndicatorKey,
    required this.onRefresh,
    required this.onRetry,
    required this.onItemTap,
  });

  final List<WatchlistItem> items;
  final bool hasError;

  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey;
  final RefreshCallback onRefresh;
  final VoidCallback onRetry;
  final ValueChanged<String> onItemTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Column(
      children: [
        if (hasError) _ErrorBanner(onRetry: onRetry),
        Expanded(
          child: RefreshIndicator(
            key: refreshIndicatorKey,
            onRefresh: onRefresh,
            color: colors.textPrimary,
            backgroundColor: colors.surfaceOverlay,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                final WatchlistItem item = items[index];
                return WatchlistRow(
                  key: ValueKey<String>(item.symbol),
                  item: item,
                  onTap: () => onItemTap(item.symbol),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return ColoredBox(
      color: colors.surfaceRaised,
      child: Padding(
        padding: EdgeInsets.only(left: dimens.space4, right: dimens.space2),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: dimens.iconSm,
              color: colors.feedbackWarning,
            ),
            SizedBox(width: dimens.space2),
            Expanded(
              child: Text(
                '정보를 불러오지 못했습니다.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.regular13.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: colors.accentDefault,
              ),
              child: const Text('다시 시도', style: AppTypography.bold13),
            ),
          ],
        ),
      ),
    );
  }
}
