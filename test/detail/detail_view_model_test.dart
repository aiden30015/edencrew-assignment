import 'package:edencrew_assignment_starter/data/dto/daily_price_dto.dart';
import 'package:edencrew_assignment_starter/data/repository/stock_repository.dart';
import 'package:edencrew_assignment_starter/features/detail/detail_view_model.dart';
import 'package:edencrew_assignment_starter/features/detail/models/candle.dart';
import 'package:edencrew_assignment_starter/features/detail/models/chart_period.dart';
import 'package:edencrew_assignment_starter/shared/utils/price_direction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/recording_stock_repository.dart';

DailyPriceDto _day({required int open, required int close}) => DailyPriceDto(
  localDate: '20260327',
  closePrice: close,
  changePrice: 0,
  openPrice: open,
  highPrice: close + 100,
  lowPrice: open - 100,
  accumulatedTradingVolume: 1000,
);

void main() {
  test('기간 전환은 일별 시세만 필요한 페이지만큼 더 받고, 시세는 다시 받지 않는다', () async {
    final RecordingStockRepository repo = RecordingStockRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: [stockRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final AsyncNotifierProvider<DetailViewModel, DetailState> provider =
        detailViewModelProvider('005930');
    container.listen(provider, (_, _) {});

    final DetailState first = await container.read(provider.future);
    expect(first.rows, hasLength(20));
    expect(first.candles, hasLength(20));
    expect(first.candles.last.close, first.rows.first.close);
    expect(repo.dailyPages, <int>[1, 2]);

    await container
        .read(provider.notifier)
        .selectPeriod(ChartPeriod.threeMonths);
    final DetailState second = container.read(provider).requireValue;
    expect(second.rows, hasLength(60));
    expect(repo.dailyPages, <int>[1, 2, 3, 4, 5, 6]);
    expect(repo.quoteCalls, 1);
  });

  test('저장소가 Failure를 돌려주면 첫 로딩은 AsyncError가 된다', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        stockRepositoryProvider.overrideWithValue(RecordingStockRepository()),
      ],
    );
    addTearDown(container.dispose);
    final AsyncNotifierProvider<DetailViewModel, DetailState> provider =
        detailViewModelProvider('999999');
    container.listen(provider, (_, _) {});

    await expectLater(container.read(provider.future), throwsStateError);
    expect(container.read(provider).hasError, isTrue);
  });

  test('캔들 방향은 시가 대비 종가로 정한다', () {
    expect(
      Candle.from(_day(open: 180000, close: 179700)).direction,
      PriceDirection.down,
    );
    expect(
      Candle.from(_day(open: 178900, close: 180100)).direction,
      PriceDirection.up,
    );
    expect(
      Candle.from(_day(open: 178000, close: 178000)).direction,
      PriceDirection.flat,
    );
  });
}
