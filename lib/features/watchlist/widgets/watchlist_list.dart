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
    required this.onItemRemove,
  });

  final List<WatchlistItem> items;
  final bool hasError;

  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey;
  final RefreshCallback onRefresh;
  final VoidCallback onRetry;
  final ValueChanged<String> onItemTap;
  final ValueChanged<String> onItemRemove;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Column(
      children: <Widget>[
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
                // 왼쪽으로 끝까지 밀면 바로 관심 해제. 검색 화면의 별 해제와 같은 동작이다.
                return Dismissible(
                  key: ValueKey<String>(item.symbol),
                  direction: DismissDirection.endToStart,
                  background: const _DeleteBackground(),
                  onDismissed: (_) => onItemRemove(item.symbol),
                  child: WatchlistRow(
                    item: item,
                    onTap: () => onItemTap(item.symbol),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return ColoredBox(
      color: colors.surfaceOverlay,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(right: dimens.space4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: dimens.space1,
            children: <Widget>[
              Icon(
                Icons.star_outline_rounded,
                size: dimens.iconMd,
                color: colors.textSecondary,
              ),
              Text(
                '관심 해제',
                style: AppTypography.bold13.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
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
          children: <Widget>[
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
