import 'package:flutter/material.dart';

import '../../../shared/utils/format.dart';
import '../../../shared/utils/price_direction.dart';
import '../../../theme/theme.dart';
import '../models/chart_period.dart';
import '../models/stock_detail.dart';

class PriceHeader extends StatelessWidget {
  const PriceHeader({
    super.key,
    required this.stock,
    required this.selected,
    required this.onSelect,
  });

  final StockDetail stock;
  final ChartPeriod selected;
  final ValueChanged<ChartPeriod> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.dimens.space4,
      children: [
        _PriceRow(stock: stock),
        _PeriodTabs(selected: selected, onSelect: onSelect),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.stock});

  final StockDetail stock;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final PriceDirection direction = stock.direction;
    final String arrow = switch (direction) {
      PriceDirection.up => '▲ ',
      PriceDirection.down => '▼ ',
      PriceDirection.flat => '',
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          Format.number(stock.price),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 30,
            fontWeight: AppTypography.bold,
            height: 36 / 30,
            letterSpacing: -0.4,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
        SizedBox(width: context.dimens.space2),
        Flexible(
          child: Text(
            '$arrow${Format.number(stock.change.abs())} '
            '(${Format.signedPercent(stock.changeRate)})',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.medium15.copyWith(
              color: direction.textColor(colors),
            ),
          ),
        ),
      ],
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.selected, required this.onSelect});

  static const double _height = 28;

  final ChartPeriod selected;
  final ValueChanged<ChartPeriod> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final BorderRadius radius = BorderRadius.circular(dimens.radiusMd);

    return Row(
      spacing: dimens.space1,
      children: [
        for (final ChartPeriod period in ChartPeriod.values)
          Expanded(
            child: Material(
              color: period == selected ? colors.accentBg : Colors.transparent,
              borderRadius: radius,
              child: InkWell(
                onTap: () => onSelect(period),
                borderRadius: radius,
                child: SizedBox(
                  height: _height,
                  child: Center(
                    child: Text(
                      period.label,
                      style: AppTypography.regular13.copyWith(
                        color: period == selected
                            ? colors.accentDefault
                            : colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
