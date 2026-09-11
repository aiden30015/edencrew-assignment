import '../../../data/dto/daily_price_dto.dart';
import '../../../shared/utils/price_direction.dart';

// 캔들 차트의 하루치 봉.
class Candle {
  const Candle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory Candle.from(DailyPriceDto dto) {
    return Candle(
      open: dto.openPrice,
      high: dto.highPrice,
      low: dto.lowPrice,
      close: dto.closePrice,
    );
  }

  final int open;
  final int high;
  final int low;
  final int close;

  // 당일 시가 대비 종가로 방향을 정한다. 양봉(상승) · 음봉(하락) · 도지(보합)
  PriceDirection get direction => PriceDirection.of(close - open);
}
