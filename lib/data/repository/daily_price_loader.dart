import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/utils/result.dart';
import '../dto/daily_price_dto.dart';
import 'stock_repository.dart';

// 일별 시세를 필요한 페이지만 받고, 받은 페이지는 재사용한다.
// 상세 화면의 차트 · 일별 시세 표에서 쓴다.
class DailyPriceLoader {
  DailyPriceLoader(this._repository);

  static const int pageSize = 10;

  // 한 번에 보내는 페이지 요청 수. 1년(25페이지)을 한꺼번에 보내면 같은 호스트에 요청이 몰려
  // 느려지거나 차단될 수 있어서 나눠 보낸다.
  static const int maxConcurrent = 4;

  // 생성자로 주입받아 테스트에서 가짜 저장소로 바꿀 수 있다. 밖에서는 load()만 쓰도록 private.
  final StockRepository _repository;

  // 종목코드 → 페이지 번호 → 요청 Future.
  // 결과가 아니라 Future를 저장해서, 받는 중인 페이지를 또 요청해도 중복 요청을 보내지 않는다.
  final Map<String, Map<int, Future<Result<DailyPricePageDto>>>> _cache =
      <String, Map<int, Future<Result<DailyPricePageDto>>>>{};

  // 최신 날짜부터 딱 [tradingDays]일치를 돌려준다.
  // [refreshLatest]면 캐시가 있어도 1페이지를 다시 받는다. 상세 화면에 들어올 때 쓴다.
  Future<Result<List<DailyPriceDto>>> load(
    String symbol,
    int tradingDays, {
    bool refreshLatest = false,
  }) async {
    // 이 종목의 페이지 캐시가 없으면 빈 Map으로 만든다.
    final Map<int, Future<Result<DailyPricePageDto>>> pages = _cache
        .putIfAbsent(symbol, () => <int, Future<Result<DailyPricePageDto>>>{});

    // 캐시가 없으면 아래에서 어차피 1페이지를 받으므로 따로 받지 않는다.
    if (refreshLatest && pages.containsKey(1)) {
      await _refreshFirstPage(pages, symbol);
    }

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

    // 필요한 페이지를 [maxConcurrent]개씩 요청한다. 캐시에 있는 페이지는 다시 요청하지 않는다.
    // 페이지를 순서대로 합치고, 하나라도 실패하면 남은 페이지는 요청하지 않고 전체 실패.
    final List<DailyPriceDto> items = <DailyPriceDto>[];
    // 캐시된 앞 페이지와 새로 받은 뒤 페이지 사이에 새 거래일 행이 생기면 경계에서 한 행씩 밀려
    // 같은 날짜가 두 번 온다. 날짜로 한 번만 남긴다.
    final Set<String> seen = <String>{};
    for (int start = 1; start <= needed; start += maxConcurrent) {
      final List<Result<DailyPricePageDto>> results =
          await Future.wait(<Future<Result<DailyPricePageDto>>>[
            for (
              int page = start;
              page <= min(start + maxConcurrent - 1, needed);
              page++
            )
              _page(pages, symbol, page),
          ]);
      for (final Result<DailyPricePageDto> result in results) {
        switch (result) {
          case Success(:final value):
            items.addAll(
              value.items.where((DailyPriceDto d) => seen.add(d.localDate)),
            );
          case Failure(:final error):
            return Failure<List<DailyPriceDto>>(error);
        }
      }
    }
    return Success<List<DailyPriceDto>>(items.take(tradingDays).toList());
  }

  // 1페이지를 새로 받아 맨 위 행의 날짜를 캐시와 비교한다.
  // - 같으면 행이 밀리지 않았으므로 1페이지만 바꾼다. 장중 오늘 행의 가격 · 거래량이 갱신된다.
  // - 다르면 새 거래일 행이 맨 앞에 붙어 모든 페이지가 한 칸씩 밀린 것이다.
  //   옛 2페이지 이후를 이어 붙이면 경계에서 날짜가 겹치거나 빠지므로 전부 버린다.
  // 새로 받기에 실패하면 캐시를 그대로 쓴다.
  Future<void> _refreshFirstPage(
    Map<int, Future<Result<DailyPricePageDto>>> pages,
    String symbol,
  ) async {
    final Result<DailyPricePageDto> fresh = await _repository.fetchDailyPrices(
      symbol,
      1,
    );
    if (fresh is! Success<DailyPricePageDto>) return;

    final Future<Result<DailyPricePageDto>>? cached = pages[1];
    final bool shifted = switch (await cached) {
      Success(:final value) => _newestDate(value) != _newestDate(fresh.value),
      _ => true,
    };
    if (shifted) pages.clear();
    pages[1] = Future<Result<DailyPricePageDto>>.value(fresh);
  }

  static String? _newestDate(DailyPricePageDto page) =>
      page.items.isEmpty ? null : page.items.first.localDate;

  // 캐시에 있으면 재사용하고, 없으면 요청해서 캐시에 넣는다.
  // 실패한 페이지는 캐시에서 지워서 다음 호출 때 다시 받는다.
  // 그 사이 캐시가 비워지고 같은 번호로 새 요청이 들어갔을 수 있어서, 같은 요청일 때만 지운다.
  Future<Result<DailyPricePageDto>> _page(
    Map<int, Future<Result<DailyPricePageDto>>> pages,
    String symbol,
    int page,
  ) {
    return pages.putIfAbsent(page, () {
      final Future<Result<DailyPricePageDto>> future = _repository
          .fetchDailyPrices(symbol, page);
      future.then((Result<DailyPricePageDto> result) {
        if (result is Failure<DailyPricePageDto> &&
            identical(pages[page], future)) {
          pages.remove(page);
        }
      });
      return future;
    });
  }
}

final Provider<DailyPriceLoader> dailyPriceLoaderProvider =
    Provider<DailyPriceLoader>(
      (Ref ref) => DailyPriceLoader(ref.watch(stockRepositoryProvider)),
    );
