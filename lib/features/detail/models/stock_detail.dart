import '../../../data/dto/realtime_quote_dto.dart';
import '../../../data/dto/stock_meta_dto.dart';
import '../../../shared/utils/price_direction.dart';

// 상세 화면 헤더 · 현재가 · 요약 카드에 쓰는 종목 정보.
class StockDetail {
  const StockDetail({
    required this.symbol,
    required this.name,
    required this.market,
    required this.price,
    required this.change,
    required this.changeRate,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
    required this.marketCap,
  });

  // 메타 · 실시간 시세 DTO를 합치고 등락액 · 등락률 · 시가총액을 계산한다.
  factory StockDetail.from(StockMetaDto meta, RealtimeQuoteDto quote) {
    final int change = quote.currentPrice - quote.previousClose;

    return StockDetail(
      symbol: meta.symbolCode,
      name: meta.stockName,
      market: meta.stockExchangeNameKor,
      price: quote.currentPrice,
      change: change,
      changeRate: quote.previousClose == 0 ? 0 : change / quote.previousClose,
      open: quote.openPrice,
      high: quote.highPrice,
      low: quote.lowPrice,
      volume: quote.accumulatedTradingVolume,
      marketCap: quote.currentPrice * quote.countOfListedStock,
    );
  }

  final String symbol;
  final String name;

  final String market;

  final int price;
  final int change;

  final double changeRate;

  final int open;
  final int high;
  final int low;
  final int volume;

  final int marketCap;

  PriceDirection get direction => PriceDirection.of(change);

  String get subtitle => market.isEmpty ? symbol : '$symbol · $market';
}
