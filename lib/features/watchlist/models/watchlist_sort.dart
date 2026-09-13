import 'package:flutter/foundation.dart';

import 'watchlist_item.dart';

enum WatchlistSort {
  price('현재가순'),
  changeRate('등락률순'),
  name('가나다순');

  const WatchlistSort(this.label);

  final String label;
}

// 관심 목록 정렬. 안정 정렬이라 값이 같으면 등록 순서를 유지한다.
// 시세 · 종목 정보가 없는 행은 역순이어도 항상 맨 아래에 둔다.
List<WatchlistItem> sortWatchlistItems(
  List<WatchlistItem> items,
  WatchlistSort sort, {
  bool reversed = false,
}) {
  final List<WatchlistItem> result = <WatchlistItem>[...items];
  mergeSort<WatchlistItem>(
    result,
    compare: (WatchlistItem a, WatchlistItem b) => switch (sort) {
      WatchlistSort.price => _compareMissingLast<int>(
        a.quote?.price,
        b.quote?.price,
        (int x, int y) => y.compareTo(x),
        reversed,
      ),
      WatchlistSort.changeRate => _compareMissingLast<double>(
        a.quote?.changeRate,
        b.quote?.changeRate,
        (double x, double y) => y.compareTo(x),
        reversed,
      ),
      WatchlistSort.name => _compareMissingLast<String>(
        a.name,
        b.name,
        _compareName,
        reversed,
      ),
    },
  );
  return result;
}

int _compareMissingLast<T>(
  T? a,
  T? b,
  int Function(T a, T b) compare,
  bool reversed,
) {
  if (a == null) return b == null ? 0 : 1;
  if (b == null) return -1;
  return reversed ? compare(b, a) : compare(a, b);
}

// 한글로 시작하는 이름이 먼저, 영문 · 숫자로 시작하는 이름이 뒤.
int _compareName(String a, String b) {
  final int group = _nameGroup(a).compareTo(_nameGroup(b));
  return group != 0 ? group : a.compareTo(b);
}

int _nameGroup(String name) {
  if (name.isEmpty) return 1;
  final int code = name.codeUnitAt(0);
  return code >= 0xAC00 && code <= 0xD7A3 ? 0 : 1;
}
