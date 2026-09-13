import 'package:edencrew_assignment_starter/features/watchlist/models/watchlist_item.dart';
import 'package:edencrew_assignment_starter/features/watchlist/models/watchlist_sort.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WatchlistItem item(String symbol, {String? name, int? price, int? prev}) {
    return WatchlistItem(
      symbol: symbol,
      name: name,
      market: name == null ? null : '코스피',
      quote: price == null
          ? null
          : WatchlistQuote(
              price: price,
              change: price - prev!,
              changeRate: (price - prev) / prev,
            ),
    );
  }

  final List<WatchlistItem> items = <WatchlistItem>[
    item('005930', name: '삼성전자', price: 179700, prev: 180100),
    item('373220', name: 'LG에너지솔루션'),
    item('000660', name: 'SK하이닉스', price: 412500, prev: 403000),
    item('035720', name: '카카오', price: 61300, prev: 62100),
    item('999999'),
    item('247540', name: '에코프로비엠', price: 184000, prev: 184000),
    item('010140', name: '삼성중공업', price: 21350, prev: 20000),
  ];

  List<String> symbols(WatchlistSort sort, {bool reversed = false}) => <String>[
    for (final WatchlistItem i in sortWatchlistItems(
      items,
      sort,
      reversed: reversed,
    ))
      i.symbol,
  ];

  test('현재가순: 높은 가격부터, 시세 없는 행은 등록 순서대로 맨 아래', () {
    expect(symbols(WatchlistSort.price), <String>[
      '000660',
      '247540',
      '005930',
      '035720',
      '010140',
      '373220',
      '999999',
    ]);
  });

  test('등락률순: 높은 등락률부터, 시세 없는 행은 맨 아래', () {
    expect(symbols(WatchlistSort.changeRate), <String>[
      '010140',
      '000660',
      '247540',
      '005930',
      '035720',
      '373220',
      '999999',
    ]);
  });

  test('가나다순: 한글 이름 먼저, 영문 이름 다음, 종목 정보 없는 행은 맨 아래', () {
    expect(symbols(WatchlistSort.name), <String>[
      '005930',
      '010140',
      '247540',
      '035720',
      '373220',
      '000660',
      '999999',
    ]);
  });

  test('역순: 방향만 뒤집고 시세 없는 행은 여전히 맨 아래', () {
    expect(symbols(WatchlistSort.price, reversed: true), <String>[
      '010140',
      '035720',
      '005930',
      '247540',
      '000660',
      '373220',
      '999999',
    ]);
  });

  test('원본 목록은 바꾸지 않는다', () {
    sortWatchlistItems(items, WatchlistSort.price);
    expect(items.first.symbol, '005930');
  });
}
