import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/widgets/retry_view.dart';
import '../../../theme/theme.dart';
import '../models/candle.dart';

// 캔들 차트. 오래된 날짜가 왼쪽.
// - 로딩 중: 이전 차트를 흐리게 두고 가운데 스피너
// - 실패: 차트 자리에 `다시 시도`
// - 데이터 없음: 안내 문구
class CandleChart extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return SizedBox(
      height: _height,
      child: hasError
          ? RetryView(
              showIcon: false,
              message: '시세를 불러오지 못했습니다.',
              onRetry: onRetry,
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: isLoading ? 0.4 : 1,
                    child: _buildChart(context, colors),
                  ),
                ),
                if (isLoading)
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
    if (candles.isEmpty) {
      return Center(
        child: Text(
          '표시할 시세가 없습니다',
          style: AppTypography.regular13.copyWith(color: colors.textTertiary),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dimens.space5),
      child: CustomPaint(
        size: Size.infinite,
        painter: _CandlePainter(candles: candles, colors: colors),
      ),
    );
  }
}

// 실제로 캔들을 그리는 painter.
class _CandlePainter extends CustomPainter {
  _CandlePainter({required this.candles, required this.colors});

  final List<Candle> candles;
  final AppColors colors;

  // 캔들 한 칸에서 몸통이 차지하는 비율. 나머지는 캔들 사이 간격.
  static const double _bodyRatio = 0.6;

  @override
  void paint(Canvas canvas, Size size) {
    // 기간 내 최저가 ~ 최고가를 Y축 범위로 쓴다.
    final int maxPrice = candles.map((Candle c) => c.high).reduce(max);
    final int minPrice = candles.map((Candle c) => c.low).reduce(min);
    // 가격 폭. 0으로 나누지 않도록 최소 1.
    final double range = max(1, maxPrice - minPrice).toDouble();
    // 가격 → y좌표. Canvas는 위가 0이라 가격이 높을수록 y가 작다.
    // 모든 값이 같으면 가운데 한 줄로 그린다.
    double y(int price) => maxPrice == minPrice
        ? size.height / 2
        : (maxPrice - price) / range * size.height;
    // 캔들 한 칸의 폭
    final double slot = size.width / candles.length;
    // 몸통 폭. 캔들이 많아 칸이 좁아도 최소 1px
    final double bodyWidth = max(1, slot * _bodyRatio);
    // 꼬리 선 두께. 몸통은 채우기라 영향 없음
    final Paint paint = Paint()..strokeWidth = 1;
    for (int i = 0; i < candles.length; i++) {
      final Candle c = candles[i];
      // i번째 칸의 가운데 x
      final double cx = slot * i + slot / 2;
      // 상승 · 하락 · 보합에 따라 색이 바뀐다
      paint.color = c.direction.candleColor(colors);
      // 꼬리(고가 ~ 저가)
      canvas.drawLine(Offset(cx, y(c.high)), Offset(cx, y(c.low)), paint);
      // 몸통 윗변 = 시가 · 종가 중 높은 쪽
      final double top = y(max(c.open, c.close));
      // 시가 = 종가면 높이가 0이 되니 최소 1px 가로선으로 그린다
      final double bottom = max(y(min(c.open, c.close)), top + 1);
      // 몸통(시가 ~ 종가)
      canvas.drawRect(
        Rect.fromLTRB(cx - bodyWidth / 2, top, cx + bodyWidth / 2, bottom),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CandlePainter oldDelegate) =>
      oldDelegate.candles != candles || oldDelegate.colors != colors;
}
