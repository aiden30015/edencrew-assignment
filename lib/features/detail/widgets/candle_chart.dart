import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/utils/format.dart';
import '../../../shared/widgets/retry_view.dart';
import '../../../theme/theme.dart';
import '../models/candle.dart';

// 캔들 차트. 오래된 날짜가 왼쪽.
// - 위: 캔들 + 종가 영역 채우기 + 오른쪽 가격 축, 아래: 거래량 막대
// - 길게 누른 채 좌우로 움직이면 크로스헤어와 그날 시세 툴팁
// - 기간을 바꾸면 새 차트가 겹쳐 흐려지며 바뀐다
// - 로딩 중: 이전 차트를 흐리게 두고 가운데 스피너
// - 실패: 차트 자리에 `다시 시도`
// - 데이터 없음: 안내 문구
class CandleChart extends StatefulWidget {
  const CandleChart({
    super.key,
    required this.candles,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
  });

  static const double _height = 200;

  final List<Candle> candles;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;

  @override
  State<CandleChart> createState() => _CandleChartState();
}

class _CandleChartState extends State<CandleChart> {
  // 크로스헤어가 가리키는 캔들. 손을 떼면 null.
  int? _selected;

  @override
  void didUpdateWidget(CandleChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candles != widget.candles) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return SizedBox(
      height: CandleChart._height,
      child: widget.hasError
          ? RetryView(
              showIcon: false,
              message: '시세를 불러오지 못했습니다.',
              onRetry: widget.onRetry,
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: widget.isLoading ? 0.4 : 1,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: KeyedSubtree(
                        key: ObjectKey(widget.candles),
                        child: _buildChart(context, colors),
                      ),
                    ),
                  ),
                ),
                if (widget.isLoading)
                  SizedBox.square(
                    dimension: context.dimens.iconMd,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.accentDefault,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildChart(BuildContext context, AppColors colors) {
    final List<Candle> candles = widget.candles;
    if (candles.isEmpty) {
      return Center(
        child: Text(
          '표시할 시세가 없습니다',
          style: AppTypography.regular13.copyWith(color: colors.textTertiary),
        ),
      );
    }

    final TextStyle axisStyle = AppTypography.regular11.copyWith(
      color: colors.chartAxisLabel,
    );
    final _PriceAxis axis = _PriceAxis.of(
      candles,
      axisStyle,
      gap: context.dimens.space2,
    );
    final int? selected = _selected;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dimens.space3),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double plotWidth = constraints.maxWidth - axis.width;
          int indexAt(Offset position) =>
              (position.dx / plotWidth * candles.length).floor().clamp(
                0,
                candles.length - 1,
              );

          return GestureDetector(
            onLongPressStart: (LongPressStartDetails d) =>
                setState(() => _selected = indexAt(d.localPosition)),
            onLongPressMoveUpdate: (LongPressMoveUpdateDetails d) =>
                setState(() => _selected = indexAt(d.localPosition)),
            onLongPressEnd: (_) => setState(() => _selected = null),
            onLongPressCancel: () => setState(() => _selected = null),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CandlePainter(
                      candles: candles,
                      colors: colors,
                      axis: axis,
                      selected: selected,
                    ),
                  ),
                ),
                if (selected != null)
                  Positioned(
                    top: 0,
                    // 손가락 반대쪽에 띄워서 가리키는 캔들을 가리지 않는다.
                    left: selected >= candles.length / 2 ? 0 : null,
                    right: selected < candles.length / 2 ? axis.width : null,
                    child: _Tooltip(candle: candles[selected]),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// 오른쪽 가격 축. 기간 내 최고가 · 중간 · 최저가 세 줄.
class _PriceAxis {
  _PriceAxis({
    required this.maxPrice,
    required this.minPrice,
    required this.labels,
    required this.width,
  });

  factory _PriceAxis.of(
    List<Candle> candles,
    TextStyle style, {
    required double gap,
  }) {
    final int maxPrice = candles.map((Candle c) => c.high).reduce(max);
    final int minPrice = candles.map((Candle c) => c.low).reduce(min);
    final List<TextPainter> labels = <TextPainter>[
      for (final int price in <int>[
        maxPrice,
        (maxPrice + minPrice) ~/ 2,
        minPrice,
      ])
        TextPainter(
          text: TextSpan(text: Format.number(price), style: style),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
    // 가장 긴 라벨 + 차트와의 간격
    final double width =
        labels.map((TextPainter p) => p.width).reduce(max) + gap;
    return _PriceAxis(
      maxPrice: maxPrice,
      minPrice: minPrice,
      labels: labels,
      width: width,
    );
  }

  final int maxPrice;
  final int minPrice;
  final List<TextPainter> labels;
  final double width;
}

// 실제로 캔들을 그리는 painter.
class _CandlePainter extends CustomPainter {
  _CandlePainter({
    required this.candles,
    required this.colors,
    required this.axis,
    required this.selected,
  });

  final List<Candle> candles;
  final AppColors colors;
  final _PriceAxis axis;
  final int? selected;

  // 캔들 한 칸에서 몸통이 차지하는 비율. 나머지는 캔들 사이 간격.
  static const double _bodyRatio = 0.6;

  // 전체 높이 중 가격 영역 · 거래량 영역 비율. 사이는 여백.
  static const double _priceRatio = 0.74;
  static const double _volumeRatio = 0.18;

  @override
  void paint(Canvas canvas, Size size) {
    final double plotWidth = size.width - axis.width;
    final Rect priceRect = Rect.fromLTWH(
      0,
      0,
      plotWidth,
      size.height * _priceRatio,
    );
    final Rect volumeRect = Rect.fromLTRB(
      0,
      size.height * (1 - _volumeRatio),
      plotWidth,
      size.height,
    );

    final int maxPrice = axis.maxPrice;
    final int minPrice = axis.minPrice;
    // 가격 폭. 0으로 나누지 않도록 최소 1.
    final double range = max(1, maxPrice - minPrice).toDouble();
    // 가격 → y좌표. Canvas는 위가 0이라 가격이 높을수록 y가 작다.
    // 모든 값이 같으면 가운데 한 줄로 그린다.
    double y(int price) => maxPrice == minPrice
        ? priceRect.center.dy
        : priceRect.top + (maxPrice - price) / range * priceRect.height;
    // 캔들 한 칸의 폭
    final double slot = plotWidth / candles.length;
    // i번째 칸의 가운데 x
    double cx(int i) => slot * i + slot / 2;

    _paintAxis(canvas, size, priceRect);
    _paintArea(canvas, priceRect, cx, y);
    _paintVolumes(canvas, volumeRect, slot, cx);
    _paintCandles(canvas, slot, cx, y);
    final int? selected = this.selected;
    if (selected != null) {
      _paintCrosshair(canvas, priceRect, volumeRect, cx(selected), y);
    }
  }

  // 가격 라벨 세 개와 그 높이의 가로 기준선.
  void _paintAxis(Canvas canvas, Size size, Rect priceRect) {
    final Paint line = Paint()
      ..color = colors.chartBaseline
      ..strokeWidth = 0.5;
    for (int i = 0; i < axis.labels.length; i++) {
      final double y = priceRect.top + priceRect.height * i / 2;
      canvas.drawLine(Offset(0, y), Offset(priceRect.right, y), line);
      final TextPainter label = axis.labels[i];
      label.paint(
        canvas,
        Offset(size.width - label.width, y - label.height / 2),
      );
    }
  }

  // 종가를 이은 선 아래를 기간 전체 등락 방향 색으로 옅게 채운다.
  void _paintArea(
    Canvas canvas,
    Rect priceRect,
    double Function(int) cx,
    double Function(int) y,
  ) {
    final Path path = Path()..moveTo(cx(0), priceRect.bottom);
    for (int i = 0; i < candles.length; i++) {
      path.lineTo(cx(i), y(candles[i].close));
    }
    path
      ..lineTo(cx(candles.length - 1), priceRect.bottom)
      ..close();
    final bool rising = candles.last.close >= candles.first.close;
    canvas.drawPath(
      path,
      Paint()..color = rising ? colors.chartAreaUp : colors.chartAreaDown,
    );
  }

  // 거래량 막대. 기간 내 최대 거래량을 영역 높이로 본다.
  void _paintVolumes(
    Canvas canvas,
    Rect volumeRect,
    double slot,
    double Function(int) cx,
  ) {
    final int maxVolume = max(
      1,
      candles.map((Candle c) => c.volume).reduce(max),
    );
    final double barWidth = max(1, slot * _bodyRatio);
    final Paint paint = Paint()..color = colors.chartVolumeBar;
    for (int i = 0; i < candles.length; i++) {
      final double height = volumeRect.height * candles[i].volume / maxVolume;
      canvas.drawRect(
        Rect.fromLTRB(
          cx(i) - barWidth / 2,
          volumeRect.bottom - max(1, height),
          cx(i) + barWidth / 2,
          volumeRect.bottom,
        ),
        paint,
      );
    }
  }

  void _paintCandles(
    Canvas canvas,
    double slot,
    double Function(int) cx,
    double Function(int) y,
  ) {
    // 몸통 폭. 캔들이 많아 칸이 좁아도 최소 1px
    final double bodyWidth = max(1, slot * _bodyRatio);
    // 꼬리 선 두께. 몸통은 채우기라 영향 없음
    final Paint paint = Paint()..strokeWidth = 1;
    for (int i = 0; i < candles.length; i++) {
      final Candle c = candles[i];
      final double x = cx(i);
      // 상승 · 하락 · 보합에 따라 색이 바뀐다
      paint.color = c.direction.candleColor(colors);
      // 꼬리(고가 ~ 저가)
      canvas.drawLine(Offset(x, y(c.high)), Offset(x, y(c.low)), paint);
      // 몸통 윗변 = 시가 · 종가 중 높은 쪽
      final double top = y(max(c.open, c.close));
      // 시가 = 종가면 높이가 0이 되니 최소 1px 가로선으로 그린다
      final double bottom = max(y(min(c.open, c.close)), top + 1);
      // 몸통(시가 ~ 종가)
      canvas.drawRect(
        Rect.fromLTRB(x - bodyWidth / 2, top, x + bodyWidth / 2, bottom),
        paint,
      );
    }
  }

  // 세로선은 가격 · 거래량 영역을 관통하고, 가로선은 그날 종가 높이.
  void _paintCrosshair(
    Canvas canvas,
    Rect priceRect,
    Rect volumeRect,
    double x,
    double Function(int) y,
  ) {
    final Paint line = Paint()
      ..color = colors.textTertiary
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(x, priceRect.top),
      Offset(x, volumeRect.bottom),
      line,
    );
    final double closeY = y(candles[selected!].close);
    canvas.drawLine(
      Offset(priceRect.left, closeY),
      Offset(priceRect.right, closeY),
      line,
    );
  }

  @override
  bool shouldRepaint(_CandlePainter oldDelegate) =>
      oldDelegate.candles != candles ||
      oldDelegate.colors != colors ||
      oldDelegate.selected != selected;
}

class _Tooltip extends StatelessWidget {
  const _Tooltip({required this.candle});

  final Candle candle;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final TextStyle label = AppTypography.regular11.copyWith(
      color: colors.textSecondary,
    );
    final TextStyle value = AppTypography.regular11.copyWith(
      color: colors.textPrimary,
    );

    TableRow row(String name, String text) => TableRow(
      children: [
        Padding(
          padding: EdgeInsets.only(right: dimens.space2),
          child: Text(name, style: label),
        ),
        Text(text, style: value, textAlign: TextAlign.right),
      ],
    );

    return IgnorePointer(
      child: Container(
        padding: EdgeInsets.all(dimens.space2),
        decoration: BoxDecoration(
          color: colors.surfaceOverlay,
          borderRadius: BorderRadius.circular(dimens.radiusMd),
          border: Border.all(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Format.monthDay(candle.date),
              style: AppTypography.bold13.copyWith(color: colors.textPrimary),
            ),
            SizedBox(height: dimens.space1),
            Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                row('시가', Format.number(candle.open)),
                row('고가', Format.number(candle.high)),
                row('저가', Format.number(candle.low)),
                row('종가', Format.number(candle.close)),
                row('거래량', Format.volume(candle.volume)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
