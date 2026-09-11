import 'dart:math';

import '../../shared/utils/result.dart';
import '../dto/autocomplete_item_dto.dart';
import '../dto/daily_price_dto.dart';
import '../dto/realtime_quote_dto.dart';
import '../dto/stock_meta_dto.dart';
import 'stock_repository.dart';

// 서버 연결 전에 쓰는 샘플 저장소. 응답 모양은 실제 DTO와 같다.
// 로딩 스켈레톤을 확인할 수 있게 응답마다 [latency]만큼 지연을 둔다.
class FakeStockRepository implements StockRepository {
  FakeStockRepository({this.latency = const Duration(milliseconds: 600)});

  final Duration latency;

  static const int _lastPage = 30;

  static const Map<String, (String, String, int, int, int)> _stocks =
      <String, (String, String, int, int, int)>{
        '005930': ('삼성전자', '코스피', 179700, 180100, 5846278608),
        '000660': ('SK하이닉스', '코스피', 412500, 403000, 730492365),
        '035720': ('카카오', '코스피', 61300, 62100, 443090000),
        '247540': ('에코프로비엠', '코스닥', 184000, 184000, 97801344),
        '373220': ('LG에너지솔루션', '코스피', 391500, 386000, 234000000),
        '005935': ('삼성전자우', '코스피', 145200, 145900, 815974664),
        '207940': ('삼성바이오로직스', '코스피', 1043000, 1051000, 71174000),
        '018260': ('삼성에스디에스', '코스피', 158300, 157000, 77377800),
        '010140': ('삼성중공업', '코스피', 21350, 20900, 880000000),
        '006400': ('삼성SDI', '코스피', 236500, 241000, 68764530),
        '028260': ('삼성물산', '코스피', 168900, 168900, 169976544),
        '032830': ('삼성생명', '코스피', 121700, 120300, 200000000),
        '009150': ('삼성전기', '코스피', 172400, 176500, 74693696),
        '000810': ('삼성화재', '코스피', 402000, 398500, 47374837),
        '448730': ('삼성FN리츠기업구조조정부동산투자회사', '코스피', 5120, 5150, 80000000),
      };

  @override
  Future<Result<List<AutocompleteItemDto>>> search(String query) async {
    await Future<void>.delayed(latency ~/ 2);
    final String q = query.trim();
    if (q.isEmpty) return const Success<List<AutocompleteItemDto>>([]);

    return Success<List<AutocompleteItemDto>>(<AutocompleteItemDto>[
      for (final MapEntry<String, (String, String, int, int, int)> e
          in _stocks.entries)
        if (e.value.$1.contains(q) || e.key.startsWith(q))
          AutocompleteItemDto(
            code: e.key,
            name: e.value.$1,
            typeCode: e.value.$2 == '코스피' ? 'KOSPI' : 'KOSDAQ',
            typeName: e.value.$2,
            nationCode: 'KOR',
            category: 'stock',
          ),
    ]);
  }

  @override
  Future<Result<RealtimeQuotesDto>> fetchQuotes(List<String> symbols) async {
    await Future<void>.delayed(latency);
    return Success<RealtimeQuotesDto>(
      RealtimeQuotesDto(
        quotes: <String, RealtimeQuoteDto>{
          for (final String symbol in symbols)
            if (_stocks[symbol] case final (String, String, int, int, int) s)
              symbol: RealtimeQuoteDto(
                symbolCode: symbol,
                currentPrice: s.$3,
                previousClose: s.$4,
                openPrice: s.$4,
                highPrice: max(s.$3, s.$4) + s.$3 ~/ 100,
                lowPrice: min(s.$3, s.$4) - s.$3 ~/ 100,
                accumulatedTradingVolume: 29113000 + symbol.hashCode % 1000000,
                countOfListedStock: s.$5,
              ),
        },
      ),
    );
  }

  @override
  Future<Result<StockMetaDto>> fetchMeta(String symbol) async {
    await Future<void>.delayed(latency ~/ 3);
    final (String, String, int, int, int)? s = _stocks[symbol];
    if (s == null) return Failure<StockMetaDto>(_unknown(symbol));
    return Success<StockMetaDto>(
      StockMetaDto(
        symbolCode: symbol,
        stockName: s.$1,
        stockExchangeNameKor: s.$2,
      ),
    );
  }

  @override
  Future<Result<DailyPricePageDto>> fetchDailyPrices(
    String symbol,
    int page,
  ) async {
    await Future<void>.delayed(latency ~/ 3);
    final (String, String, int, int, int)? s = _stocks[symbol];
    if (s == null) return Failure<DailyPricePageDto>(_unknown(symbol));
    if (page < 1 || page > _lastPage) {
      return const Success<DailyPricePageDto>(
        DailyPricePageDto(items: <DailyPriceDto>[], lastPage: _lastPage),
      );
    }

    final List<DailyPriceDto> all = _dailySeries(symbol, s.$4);
    final int start = (page - 1) * 10;
    return Success<DailyPricePageDto>(
      DailyPricePageDto(
        items: all.sublist(start, min(start + 10, all.length)),
        lastPage: _lastPage,
      ),
    );
  }

  static StateError _unknown(String symbol) =>
      StateError('unknown symbol: $symbol');

  List<DailyPriceDto> _dailySeries(String symbol, int latestClose) {
    final Random random = Random(int.parse(symbol));
    final List<DailyPriceDto> result = <DailyPriceDto>[];
    DateTime day = DateTime.now();
    int close = latestClose;

    final List<int> closes = <int>[];

    while (result.length <= _lastPage * 10) {
      day = day.subtract(const Duration(days: 1));
      if (day.weekday > DateTime.friday) continue;

      final int step = max(1, close ~/ 60);
      final int open = close + (random.nextInt(step * 2 + 1) - step);
      final int high = max(open, close) + random.nextInt(step + 1);
      final int low = max(1, min(open, close) - random.nextInt(step + 1));
      result.add(
        DailyPriceDto(
          localDate: '${day.year}${_two(day.month)}${_two(day.day)}',
          closePrice: close,
          changePrice: 0,
          openPrice: open,
          highPrice: high,
          lowPrice: low,
          accumulatedTradingVolume: 8000000 + random.nextInt(30000000),
        ),
      );
      closes.add(close);
      close = max(1, open + (random.nextInt(step + 1) - step ~/ 2));
    }

    return <DailyPriceDto>[
      for (int i = 0; i < _lastPage * 10; i++)
        DailyPriceDto(
          localDate: result[i].localDate,
          closePrice: result[i].closePrice,
          changePrice: closes[i] - closes[i + 1],
          openPrice: result[i].openPrice,
          highPrice: result[i].highPrice,
          lowPrice: result[i].lowPrice,
          accumulatedTradingVolume: result[i].accumulatedTradingVolume,
        ),
    ];
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}
