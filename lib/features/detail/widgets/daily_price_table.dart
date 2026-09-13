import 'package:flutter/material.dart';

import '../../../shared/utils/format.dart';
import '../../../theme/theme.dart';
import '../models/daily_price_row.dart';

const double _rowHeight = 32;

class DailyPriceTable extends StatelessWidget {
  const DailyPriceTable({
    super.key,
    required this.rows,
    required this.isLoading,
  });

  final List<DailyPriceRow> rows;

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;

    return SliverMainAxisGroup(
      slivers: <Widget>[
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            dimens.space4,
            0,
            dimens.space4,
            dimens.space1,
          ),
          sliver: SliverToBoxAdapter(
            child: Text(
              '일별 시세',
              style: AppTypography.bold13.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: _HeaderRow()),
        SliverOpacity(
          opacity: isLoading ? 0.4 : 1,
          sliver: SliverFixedExtentList.builder(
            itemExtent: _rowHeight,
            itemCount: rows.length,
            itemBuilder: (BuildContext context, int index) => _DataRow(
              row: rows[index],
              showDivider: index < rows.length - 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTypography.regular11.copyWith(
      color: context.colors.textSecondary,
    );

    return _TableRowFrame(
      showDivider: true,
      date: Text('날짜', style: style),
      close: Text('종가', style: style),
      change: Text('등락', style: style),
      volume: Text('거래량', style: style),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.row, required this.showDivider});

  final DailyPriceRow row;

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextStyle base = AppTypography.regular11.copyWith(
      color: colors.textSecondary,
    );

    return _TableRowFrame(
      showDivider: showDivider,
      date: Text(Format.monthDay(row.date), style: base),
      close: Text(
        Format.number(row.close),
        style: base.copyWith(color: colors.textPrimary),
      ),
      change: Text(
        Format.signedNumber(row.change),
        style: base.copyWith(color: row.direction.textColor(colors)),
      ),
      volume: Text(Format.number(row.volume), style: base),
    );
  }
}

class _TableRowFrame extends StatelessWidget {
  const _TableRowFrame({
    required this.showDivider,
    required this.date,
    required this.close,
    required this.change,
    required this.volume,
  });

  final bool showDivider;
  final Widget date;
  final Widget close;
  final Widget change;
  final Widget volume;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      height: _rowHeight,
      margin: EdgeInsets.symmetric(horizontal: dimens.space4),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.borderSubtle,
                  width: dimens.borderHairline,
                ),
              )
            : null,
      ),
      child: Row(
        children: <Widget>[
          Expanded(flex: 4, child: date),
          Expanded(
            flex: 9,
            child: Align(alignment: Alignment.centerRight, child: close),
          ),
          Expanded(
            flex: 9,
            child: Align(alignment: Alignment.centerRight, child: change),
          ),
          Expanded(
            flex: 9,
            child: Align(alignment: Alignment.centerRight, child: volume),
          ),
        ],
      ),
    );
  }
}
