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

  test('날짜가 바뀌면 받은 페이지를 버리고 다시 받는다', () async {
    final RecordingStockRepository repo = RecordingStockRepository();
    DateTime now = DateTime(2026, 9, 11, 15);
    final DailyPriceLoader loader = DailyPriceLoader(repo, now: () => now);

    await _load(loader, 20);
    expect(repo.dailyPages, <int>[1, 2]);

    now = DateTime(2026, 9, 11, 23, 59);
    await _load(loader, 20);
    expect(repo.dailyPages, <int>[1, 2]);

    now = DateTime(2026, 9, 12, 9);
    await _load(loader, 20);
    expect(repo.dailyPages, <int>[1, 2, 1, 2]);
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
