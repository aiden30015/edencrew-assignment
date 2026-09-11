// 종목 기본 정보(코드 · 이름 · 시장). 가격처럼 자주 바뀌지 않는 값.
class StockMetaDto {
  const StockMetaDto({
    required this.symbolCode,
    required this.stockName,
    required this.stockExchangeNameKor,
  });

  factory StockMetaDto.fromJson(Map<String, dynamic> json) {
    return StockMetaDto(
      symbolCode: json['symbolCode'] as String,
      stockName: json['stockName'] as String,
      stockExchangeNameKor: json['stockExchangeNameKor'] as String? ?? '',
    );
  }

  final String symbolCode;
  final String stockName;

  final String stockExchangeNameKor;
}
