// 실시간 시세 API(polling.finance.naver.com/api/realtime) 응답의 종목 하나.
// 서버 JSON 키(cd, nv, pcv ...)는 fromJson에서만 쓰고 필드는 읽기 쉬운 이름으로 둔다.
class RealtimeQuoteDto {
  const RealtimeQuoteDto({
    required this.symbolCode,
    required this.currentPrice,
    required this.previousClose,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.accumulatedTradingVolume,
    required this.countOfListedStock,
  });

  factory RealtimeQuoteDto.fromJson(Map<String, dynamic> json) {
    int toInt(String key) => (json[key] as num?)?.toInt() ?? 0;

    return RealtimeQuoteDto(
      symbolCode: json['cd'] as String,
      currentPrice: toInt('nv'),
      previousClose: toInt('pcv'),
      openPrice: toInt('ov'),
      highPrice: toInt('hv'),
      lowPrice: toInt('lv'),
      accumulatedTradingVolume: toInt('aq'),
      countOfListedStock: toInt('countOfListedStock'),
    );
  }

  final String symbolCode;

  final int currentPrice;

  final int previousClose;

  final int openPrice;

  final int highPrice;

  final int lowPrice;

  final int accumulatedTradingVolume;

  final int countOfListedStock;
}
