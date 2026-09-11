// 일별 시세 한 페이지(최대 10거래일, 최신 날짜가 앞). 상세 화면의 차트 · 표에 쓴다.
class DailyPricePageDto {
  const DailyPricePageDto({required this.items, required this.lastPage});

  final List<DailyPriceDto> items;
  final int lastPage;
}

class DailyPriceDto {
  const DailyPriceDto({
    required this.localDate,
    required this.closePrice,
    required this.changePrice,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.accumulatedTradingVolume,
  });

  final String localDate;
  final int closePrice;

  final int changePrice;
  final int openPrice;
  final int highPrice;
  final int lowPrice;
  final int accumulatedTradingVolume;
}
