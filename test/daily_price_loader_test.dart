import 'dart:math';

import 'package:edencrew_assignment_starter/data/dto/daily_price_dto.dart';
import 'package:edencrew_assignment_starter/data/repository/daily_price_loader.dart';
import 'package:edencrew_assignment_starter/shared/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/recording_stock_repository.dart';

Future<List<DailyPriceDto>> _load(
  DailyPriceLoader loader,
  int tradingDays,
) async => switch (await loader.load('005930', tradingDays)) {
  Success(:final value) => value,
  Failure(:final error) => throw error,
};

void main() {
  test('필요한 페이지만 받고, 받은 페이지는 재사용한다', () async {
    final RecordingStockRepository repo = RecordingStockRepository();
    final DailyPriceLoader loader = DailyPriceLoader(repo);

    expect(await _load(loader, 20), hasLength(20));
    expect(repo.dailyPages, <int>[1, 2]);

    expect(await _load(loader, 60), hasLength(60));
    expect(repo.dailyPages, <int>[1, 2, 3, 4, 5, 6]);

    await _load(loader, 20);
    expect(repo.dailyPages, hasLength(6));
  });

  test('처음 들어올 때는 refreshLatest여도 1페이지를 한 번만 받는다', () async {
    final RecordingStockRepository repo = RecordingStockRepository();
    final DailyPriceLoader loader = DailyPriceLoader(repo);

    await loader.load('005930', 20, refreshLatest: true);
    expect(repo.dailyPages, <int>[1, 2]);
  });

  test('다시 들어오면 1페이지만 새로 받고, 맨 위 날짜가 같으면 나머지는 재사용한다', () async {
    final _ChangingRepository repo = _ChangingRepository();
    final DailyPriceLoader loader = DailyPriceLoader(repo);
    await _load(loader, 60);

    repo.intraday = true;
    final List<DailyPriceDto> days = switch (await loader.load(
      '005930',
      60,
      refreshLatest: true,
    )) {
      Success(:final value) => value,
      Failure(:final error) => throw error,
    };

    expect(repo.dailyPages, <int>[1, 2, 3, 4, 5, 6, 1]);
    expect(days.first.closePrice, _ChangingRepository.intradayClose);
    expect(days, hasLength(60));
  });

  test('맨 위 날짜가 바뀌었으면 행이 밀린 것이라 캐시를 버리고 다시 받는다', () async {
    final _ChangingRepository repo = _ChangingRepository();
    final DailyPriceLoader loader = DailyPriceLoader(repo);
    await _load(loader, 60);

    repo.newDay = true;
    final List<DailyPriceDto> days = switch (await loader.load(
      '005930',
      60,
      refreshLatest: true,
    )) {
      Success(:final value) => value,
      Failure(:final error) => throw error,
    };

    expect(repo.dailyPages, <int>[1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6]);
    expect(days.first.localDate, _ChangingRepository.newDate);
  });

  test('lastPage보다 큰 페이지는 요청하지 않는다', () async {
    final RecordingStockRepository repo = RecordingStockRepository();
    final DailyPriceLoader loader = DailyPriceLoader(repo);

    await _load(loader, 1000);
    expect(repo.dailyPages.reduce((int a, int b) => a > b ? a : b), 30);
  });

  test('동시에 요청해도 같은 페이지를 두 번 받지 않는다', () async {
    final RecordingStockRepository repo = RecordingStockRepository();
    final DailyPriceLoader loader = DailyPriceLoader(repo);

    await Future.wait(<Future<void>>[_load(loader, 20), _load(loader, 20)]);
    expect(repo.dailyPages, <int>[1, 2]);
  });

  test('실패는 Failure로 돌려주고, 실패한 페이지는 캐시하지 않는다', () async {
    final RecordingStockRepository repo = RecordingStockRepository();
    final DailyPriceLoader loader = DailyPriceLoader(repo);

    expect(
      await loader.load('999999', 20),
      isA<Failure<List<DailyPriceDto>>>(),
    );
    await loader.load('999999', 20);
    expect(repo.dailyPages, <int>[1, 1]);
  });

  test('페이지는 maxConcurrent개씩 나눠 요청한다', () async {
    final _ConcurrencyRepository repo = _ConcurrencyRepository();
    final DailyPriceLoader loader = DailyPriceLoader(repo);

    expect(await _load(loader, 245), hasLength(245));
    expect(repo.dailyPages, <int>[for (int p = 1; p <= 25; p++) p]);
    expect(repo.maxInFlight, DailyPriceLoader.maxConcurrent);
  });

  test('캐시된 앞 페이지와 새로 받은 뒤 페이지 사이에 행이 밀려도 날짜가 겹치지 않는다', () async {
    final _ShiftingRepository repo = _ShiftingRepository();
    final DailyPriceLoader loader = DailyPriceLoader(repo);
    await _load(loader, 20);

    // 탭을 바꾸기 전에 새 거래일 행이 생겨 서버의 모든 페이지가 한 행씩 밀렸다.
    repo.shifted = true;
    final List<DailyPriceDto> days = await _load(loader, 60);

    final List<String> dates = <String>[
      for (final DailyPriceDto d in days) d.localDate,
    ];
    expect(dates.toSet(), hasLength(dates.length));
  });
}

// 동시에 진행 중인 일별 시세 요청 수의 최댓값을 기록한다.
class _ConcurrencyRepository extends RecordingStockRepository {
  int _inFlight = 0;
  int maxInFlight = 0;

  @override
  Future<Result<DailyPricePageDto>> fetchDailyPrices(
    String symbol,
    int page,
  ) async {
    _inFlight++;
    maxInFlight = max(maxInFlight, _inFlight);
    try {
      return await super.fetchDailyPrices(symbol, page);
    } finally {
      _inFlight--;
    }
  }
}

// [shifted]면 맨 앞에 새 거래일 행이 붙어 모든 페이지가 한 행씩 밀린 응답을 준다.
class _ShiftingRepository extends RecordingStockRepository {
  bool shifted = false;

  @override
  Future<Result<DailyPricePageDto>> fetchDailyPrices(
    String symbol,
    int page,
  ) async {
    final Result<DailyPricePageDto> result = await super.fetchDailyPrices(
      symbol,
      page,
    );
    if (!shifted || result is! Success<DailyPricePageDto>) return result;
    final List<DailyPriceDto> items = result.value.items;

    final DailyPriceDto carried;
    if (page == 1) {
      final DailyPriceDto top = items.first;
      carried = DailyPriceDto(
        localDate: '29991231',
        closePrice: top.closePrice,
        changePrice: top.changePrice,
        openPrice: top.openPrice,
        highPrice: top.highPrice,
        lowPrice: top.lowPrice,
        accumulatedTradingVolume: top.accumulatedTradingVolume,
      );
    } else {
      final Result<DailyPricePageDto> previous = await super.fetchDailyPrices(
        symbol,
        page - 1,
      );
      carried = (previous as Success<DailyPricePageDto>).value.items.last;
    }
    return Success<DailyPricePageDto>(
      DailyPricePageDto(
        items: <DailyPriceDto>[carried, ...items.take(items.length - 1)],
        lastPage: result.value.lastPage,
      ),
    );
  }
}

// 1페이지 응답을 바꿔 장중 갱신(같은 날짜, 다른 종가)과 새 거래일(맨 앞에 행 추가)을 흉내 낸다.
class _ChangingRepository extends RecordingStockRepository {
  static const int intradayClose = 1;
  static const String newDate = '29991231';

  bool intraday = false;
  bool newDay = false;

  @override
  Future<Result<DailyPricePageDto>> fetchDailyPrices(
    String symbol,
    int page,
  ) async {
    final Result<DailyPricePageDto> result = await super.fetchDailyPrices(
      symbol,
      page,
    );
    if (page != 1 || result is! Success<DailyPricePageDto>) return result;
    final List<DailyPriceDto> items = result.value.items;
    final DailyPriceDto top = items.first;

    DailyPriceDto withTop(String date, int close) => DailyPriceDto(
      localDate: date,
      closePrice: close,
      changePrice: top.changePrice,
      openPrice: top.openPrice,
      highPrice: top.highPrice,
      lowPrice: top.lowPrice,
      accumulatedTradingVolume: top.accumulatedTradingVolume,
    );

    final List<DailyPriceDto> changed = switch ((intraday, newDay)) {
      (_, true) => <DailyPriceDto>[
        withTop(newDate, top.closePrice),
        ...items.take(items.length - 1),
      ],
      (true, false) => <DailyPriceDto>[
        withTop(top.localDate, intradayClose),
        ...items.skip(1),
      ],
      _ => items,
    };
    return Success<DailyPricePageDto>(
      DailyPricePageDto(items: changed, lastPage: result.value.lastPage),
    );
  }
}
