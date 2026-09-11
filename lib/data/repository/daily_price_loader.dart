import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/utils/result.dart';
import '../dto/daily_price_dto.dart';
import 'stock_repository.dart';

// 일별 시세를 필요한 페이지만 받고, 받은 페이지는 재사용한다.
// 상세 화면의 차트 · 일별 시세 표에서 쓴다.
class DailyPriceLoader {
  DailyPriceLoader(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const int pageSize = 10;

  // 생성자로 주입받아 테스트에서 가짜 저장소로 바꿀 수 있다. 밖에서는 load()만 쓰도록 private.
  final StockRepository _repository;

  // 테스트에서 날짜를 바꿔 끼우기 위한 시계.
  final DateTime Function() _now;

  // 종목코드 → 페이지 번호 → 요청 Future.
  // 결과가 아니라 Future를 저장해서, 받는 중인 페이지를 또 요청해도 중복 요청을 보내지 않는다.
  final Map<String, Map<int, Future<Result<DailyPricePageDto>>>> _cache =
      <String, Map<int, Future<Result<DailyPricePageDto>>>>{};

  // 종목코드 → 캐시를 만든 날짜.
  final Map<String, DateTime> _cachedOn = <String, DateTime>{};

  // 최신 날짜부터 딱 [tradingDays]일치를 돌려준다.
  Future<Result<List<DailyPriceDto>>> load(
    String symbol,
    int tradingDays,
  ) async {
    // 날짜가 바뀌면 이 종목의 캐시를 통째로 버린다.
    // 새 거래일 행이 1페이지 맨 앞에 붙으면서 모든 페이지가 한 칸씩 밀리기 때문에,
    // 1페이지만 새로 받으면 옛 페이지와 이어지는 곳에서 날짜가 겹치거나 빠진다.
    // ponytail: 기기 날짜 기준. 같은 날 안에서는 장중 오늘 행이 처음 받은 값에 머문다.
    final DateTime now = _now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    if (_cachedOn[symbol] != today) {
      _cache.remove(symbol);
      _cachedOn[symbol] = today;
    }

    // 이 종목의 페이지 캐시가 없으면 빈 Map으로 만든다.
    final Map<int, Future<Result<DailyPricePageDto>>> pages = _cache
        .putIfAbsent(symbol, () => <int, Future<Result<DailyPricePageDto>>>{});

    final int lastPage;
    // 1페이지를 먼저 받아 전체 페이지 수(lastPage)를 알아낸다.
    switch (await _page(pages, symbol, 1)) {
      case Success(:final value):
        lastPage = value.lastPage;
      case Failure(:final error):
        return Failure<List<DailyPriceDto>>(error);
    }
    // 필요한 페이지 수. 10일 단위로 올림하되 lastPage를 넘지 않는다. (25일 → 3페이지)
    final int needed = min((tradingDays / pageSize).ceil(), lastPage);

    // 필요한 페이지를 동시에 요청한다. 1페이지는 캐시에 있어 다시 요청하지 않는다.
    final List<Result<DailyPricePageDto>> results = await Future.wait(
      <Future<Result<DailyPricePageDto>>>[
        for (int page = 1; page <= needed; page++) _page(pages, symbol, page),
      ],
    );

    // 페이지를 순서대로 합친다. 하나라도 실패하면 전체 실패.
    final List<DailyPriceDto> items = <DailyPriceDto>[];
    for (final Result<DailyPricePageDto> result in results) {
      switch (result) {
        case Success(:final value):
          items.addAll(value.items);
        case Failure(:final error):
          return Failure<List<DailyPriceDto>>(error);
      }
    }
    return Success<List<DailyPriceDto>>(items.take(tradingDays).toList());
  }

  // 캐시에 있으면 재사용하고, 없으면 요청해서 캐시에 넣는다.
  // 실패한 페이지는 캐시에서 지워서 다음 호출 때 다시 받는다.
  Future<Result<DailyPricePageDto>> _page(
    Map<int, Future<Result<DailyPricePageDto>>> pages,
    String symbol,
    int page,
  ) {
    return pages.putIfAbsent(page, () {
      final Future<Result<DailyPricePageDto>> future = _repository
          .fetchDailyPrices(symbol, page);
      future.then((Result<DailyPricePageDto> result) {
        if (result is Failure<DailyPricePageDto>) pages.remove(page);
      });
      return future;
    });
  }
}

final Provider<DailyPriceLoader> dailyPriceLoaderProvider =
    Provider<DailyPriceLoader>(
      (Ref ref) => DailyPriceLoader(ref.watch(stockRepositoryProvider)),
    );
