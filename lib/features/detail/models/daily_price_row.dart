import '../../../data/dto/daily_price_dto.dart';
import '../../../shared/utils/price_direction.dart';

// 일별 시세 표의 한 행.
class DailyPriceRow {
  const DailyPriceRow({
    required this.date,
    required this.close,
    required this.change,
    required this.volume,
  });

  factory DailyPriceRow.from(DailyPriceDto dto) {
    return DailyPriceRow(
      date: dto.localDate,
      close: dto.closePrice,
      change: dto.changePrice,
      volume: dto.accumulatedTradingVolume,
    );
  }

  final String date;
  final int close;

  final int change;
  final int volume;

  // 서버가 준 전일비 기준. 캔들(당일 시가 대비)과 기준이 달라 같은 날도 색이 다를 수 있다.
  PriceDirection get direction => PriceDirection.of(change);
}
