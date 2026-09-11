import 'package:flutter/material.dart';

import '../../../shared/utils/format.dart';
import '../../../theme/theme.dart';
import '../models/watchlist_item.dart';

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
                return _WatchlistRow(
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

class _WatchlistRow extends StatelessWidget {
  const _WatchlistRow({super.key, required this.item, required this.onTap});

  final WatchlistItem item;
  final VoidCallback onTap;

  static const double _contentHeight = 34;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final String? name = item.name;
    final WatchlistQuote? quote = item.quote;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space4,
          vertical: dimens.space3,
        ),
        foregroundDecoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colors.borderSubtle,
              width: dimens.borderHairline,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: name == null
                  ? const _SkeletonLines(
                      topWidth: 96,
                      bottomWidth: 72,
                      alignment: CrossAxisAlignment.start,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _topLineStyle(colors.textPrimary),
                        ),
                        Text(
                          item.codeAndMarket,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _bottomLineStyle(colors.textSecondary),
                        ),
                      ],
                    ),
            ),
            SizedBox(width: dimens.space3),
            if (quote == null)
              const _SkeletonLines(
                topWidth: 64,
                bottomWidth: 48,
                alignment: CrossAxisAlignment.end,
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Format.number(quote.price),
                    style: _topLineStyle(colors.textPrimary),
                  ),
                  Text(
                    '${Format.signedNumber(quote.change)} '
                    '(${Format.signedPercent(quote.changeRate)})',
                    style: _bottomLineStyle(quote.direction.textColor(colors)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static TextStyle _topLineStyle(Color color) =>
      AppTypography.medium15.copyWith(color: color);

  static TextStyle _bottomLineStyle(Color color) =>
      AppTypography.regular11.copyWith(color: color);
}

class _SkeletonLines extends StatelessWidget {
  const _SkeletonLines({
    required this.topWidth,
    required this.bottomWidth,
    required this.alignment,
  });

  final double topWidth;
  final double bottomWidth;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _WatchlistRow._contentHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: alignment,
        children: [
          _SkeletonBar(width: topWidth, height: 16),
          const SizedBox(height: 2),
          _SkeletonBar(width: bottomWidth, height: 12),
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.feedbackSkeleton,
        borderRadius: BorderRadius.circular(context.dimens.radiusSm),
      ),
    );
  }
}
