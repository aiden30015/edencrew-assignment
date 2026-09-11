import '../../../data/dto/realtime_quote_dto.dart';
import '../../../data/dto/stock_meta_dto.dart';
import '../../../shared/utils/price_direction.dart';

class WatchlistItem {
  const WatchlistItem({
    required this.symbol,
    this.name,
    this.market,
    this.quote,
  });

  factory WatchlistItem.fromDto({
    required String symbol,
    StockMetaDto? meta,
    RealtimeQuoteDto? quote,
  }) {
    return WatchlistItem(
      symbol: symbol,
      name: meta?.stockName,
      market: meta?.stockExchangeNameKor,
      quote: quote == null ? null : WatchlistQuote.fromDto(quote),
    );
  }

  final String symbol;

  final String? name;

  final String? market;

  final WatchlistQuote? quote;

  String get codeAndMarket => switch (market) {
    null || '' => symbol,
    final String market => '$symbol · $market',
  };
}

class WatchlistQuote {
  const WatchlistQuote({
    required this.price,
    required this.change,
    required this.changeRate,
  });

  factory WatchlistQuote.fromDto(RealtimeQuoteDto dto) {
    final int change = dto.currentPrice - dto.previousClose;
    return WatchlistQuote(
      price: dto.currentPrice,
      change: change,
      changeRate: dto.previousClose == 0 ? 0 : change / dto.previousClose,
    );
  }

  final int price;

  final int change;

  final double changeRate;

  PriceDirection get direction => PriceDirection.of(change);
}
