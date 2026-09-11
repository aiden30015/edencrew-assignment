import 'package:edencrew_assignment_starter/data/repository/stock_repository.dart';
import 'package:edencrew_assignment_starter/features/watchlist/watchlist_view_model.dart';
import 'package:edencrew_assignment_starter/shared/state/favorites_notifier.dart';
import 'package:edencrew_assignment_starter/shared/utils/polling.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../testing/recording_stock_repository.dart';

// testWidgets 안에서는 Timer가 가짜 시계로 돌아서 tester.pump로 시간을 넘길 수 있다.
void main() {
  const Duration interval = Duration(seconds: 7);

  testWidgets('장중이면 간격마다 조회하고, 마감이면 멈춘다', (WidgetTester tester) async {
    int ticks = 0;
    final Polling polling = Polling(() => ticks++);
    addTearDown(polling.dispose);

    polling.scheduleNext(interval, marketOpen: true);
    await tester.pump(interval);
    expect(ticks, 1);

    polling.scheduleNext(interval, marketOpen: false);
    await tester.pump(interval * 3);
    expect(ticks, 1);
  });

  testWidgets('안 보이면 멈추고, 다시 보이면 바로 한 번 조회한다', (WidgetTester tester) async {
    int ticks = 0;
    final Polling polling = Polling(() => ticks++);
    addTearDown(polling.dispose);

    polling.scheduleNext(interval, marketOpen: true);
    polling.setActive(false);
    await tester.pump(interval * 2);
    expect(ticks, 0);

    polling.setActive(true);
    expect(ticks, 1);
  });

  testWidgets('관심 목록은 서버 간격마다 시세를 한 번의 요청으로 다시 받는다', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      FavoritesNotifier.storageKey: <String>['005930', '000660'],
    });
    final RecordingStockRepository repository = RecordingStockRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        stockRepositoryProvider.overrideWithValue(repository),
        preferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(watchlistViewModelProvider, (_, _) {});

    await tester.pump();
    expect(repository.quoteCalls, 1);

    await tester.pump(interval);
    await tester.pump();
    expect(repository.quoteCalls, 2);

    container.read(watchlistViewModelProvider.notifier).setPollingActive(false);
    await tester.pump(interval * 3);
    expect(repository.quoteCalls, 2);
  });
}
