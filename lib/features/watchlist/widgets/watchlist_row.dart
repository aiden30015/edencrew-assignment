import 'package:flutter/material.dart';

import '../../../shared/utils/format.dart';
import '../../../theme/theme.dart';
import '../models/watchlist_item.dart';

class WatchlistRow extends StatelessWidget {
  const WatchlistRow({super.key, required this.item, required this.onTap});

  final WatchlistItem item;
  final VoidCallback onTap;

  static const double _contentHeight = 36;

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
        // Figma의 inside stroke처럼 구분선이 행 높이(60) 안에 그려지도록 foreground로 둡니다.
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
            // 종목명이 길어도 우측 가격 영역은 밀리지 않고 이름만 말줄임됩니다.
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
                        const SizedBox(height: 2),
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

  // 행간은 Figma처럼 글자 위아래에 고르게 나눕니다(even). 기본값(proportional)이면 글자가 1px가량 위로 뜹니다.
  static TextStyle _topLineStyle(Color color) => TextStyle(
    color: color,
    fontSize: 16,
    fontWeight: AppTypography.medium,
    height: 20 / 16,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static TextStyle _bottomLineStyle(Color color) => TextStyle(
    color: color,
    fontSize: 12,
    fontWeight: AppTypography.regular,
    height: 16 / 12,
    leadingDistribution: TextLeadingDistribution.even,
  );
}

/// 두 줄 텍스트 자리를 대신하는 스켈레톤 막대 (Figma: 64 × 16, 48 × 12, 간격 2).
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
      height: WatchlistRow._contentHeight,
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
