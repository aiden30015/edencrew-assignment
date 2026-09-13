import 'package:flutter/material.dart';

import '../../../shared/utils/format.dart';
import '../../../theme/theme.dart';
import '../models/stock_detail.dart';

class SummarySection extends StatelessWidget {
  const SummarySection({super.key, required this.stock});

  final StockDetail stock;

  @override
  Widget build(BuildContext context) {
    final double gap = context.dimens.space2;

    return Column(
      spacing: gap,
      children: <Widget>[
        Row(
          spacing: gap,
          children: <Widget>[
            _SummaryCard(label: '시가', value: Format.number(stock.open)),
            _SummaryCard(label: '고가', value: Format.number(stock.high)),
            _SummaryCard(label: '저가', value: Format.number(stock.low)),
          ],
        ),
        Row(
          spacing: gap,
          children: <Widget>[
            _SummaryCard(label: '거래량', value: Format.volume(stock.volume)),
            _SummaryCard(
              label: '시가총액',
              value: Format.marketCap(stock.marketCap),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space3,
          vertical: dimens.space2,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: BorderRadius.circular(dimens.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: dimens.space1,
          children: <Widget>[
            Text(
              label,
              maxLines: 1,
              style: AppTypography.regular11.copyWith(
                color: colors.textSecondary,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.medium15.copyWith(color: colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
