import '../../../data/dto/daily_price_dto.dart';
import '../../../shared/utils/price_direction.dart';

// 캔들 차트의 하루치 봉. 날짜 · 거래량은 거래량 막대와 크로스헤어 툴팁에 쓴다.
class Candle {
  const Candle({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory Candle.from(DailyPriceDto dto) {
    return Candle(
      date: dto.localDate,
      open: dto.openPrice,
      high: dto.highPrice,
      low: dto.lowPrice,
      close: dto.closePrice,
      volume: dto.accumulatedTradingVolume,
    );
  }

  // yyyyMMdd
  final String date;
  final int open;
  final int high;
  final int low;
  final int close;
  final int volume;

  // 당일 시가 대비 종가로 방향을 정한다. 양봉(상승) · 음봉(하락) · 도지(보합)
  PriceDirection get direction => PriceDirection.of(close - open);
}
