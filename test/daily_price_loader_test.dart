import 'package:edencrew_assignment_starter/data/dto/daily_price_dto.dart';
import 'package:edencrew_assignment_starter/data/repository/daily_price_loader.dart';
import 'package:edencrew_assignment_starter/shared/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../testing/recording_stock_repository.dart';

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
