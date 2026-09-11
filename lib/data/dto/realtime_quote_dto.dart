// 실시간 시세 응답 전체. 서버가 다음 조회까지 기다릴 간격(pollingInterval)을 같이 준다.
class RealtimeQuotesDto {
  const RealtimeQuotesDto({
    required this.quotes,
    this.pollingInterval = defaultPollingInterval,
  });

  static const Duration defaultPollingInterval = Duration(seconds: 7);

  // key는 종목코드. 응답에 없는 종목은 빠진다.
  final Map<String, RealtimeQuoteDto> quotes;
  final Duration pollingInterval;

  // 한 종목이라도 장중이면 계속 조회한다.
  bool get isMarketOpen =>
      quotes.values.any((RealtimeQuoteDto quote) => quote.isMarketOpen);
}

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
    this.marketStatus = 'OPEN',
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
      marketStatus: json['ms'] as String? ?? '',
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

  // 장 상태. 장중이면 'OPEN', 마감 후에는 'CLOSE'.
  final String marketStatus;

  bool get isMarketOpen => marketStatus == 'OPEN';
}
