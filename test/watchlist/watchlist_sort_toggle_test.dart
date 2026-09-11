import 'package:edencrew_assignment_starter/data/repository/stock_repository.dart';
import 'package:edencrew_assignment_starter/features/watchlist/models/watchlist_sort.dart';
import 'package:edencrew_assignment_starter/features/watchlist/watchlist_view_model.dart';
import 'package:edencrew_assignment_starter/shared/state/preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/fake_stock_repository.dart';

void main() {
  test('같은 기준을 다시 고르면 방향이 뒤집히고, 다른 기준은 기본 방향', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        stockRepositoryProvider.overrideWithValue(
          FakeStockRepository(latency: Duration.zero),
        ),
      ],
    );
    addTearDown(container.dispose);

    WatchlistState state() => container.read(watchlistViewModelProvider);
    final WatchlistViewModel vm = container.read(
      watchlistViewModelProvider.notifier,
    );

    expect((state().sort, state().reversed), (WatchlistSort.name, false));

    vm.changeSort(WatchlistSort.name);
    expect((state().sort, state().reversed), (WatchlistSort.name, true));

    vm.changeSort(WatchlistSort.name);
    expect(state().reversed, false);

    vm.changeSort(WatchlistSort.name);
    vm.changeSort(WatchlistSort.price);
    expect((state().sort, state().reversed), (WatchlistSort.price, false));

    await Future<void>.delayed(Duration.zero);
  });

  test('정렬 기준과 방향이 앱 재실행 후에도 유지된다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    Future<ProviderContainer> launch() async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          stockRepositoryProvider.overrideWithValue(
            FakeStockRepository(latency: Duration.zero),
          ),
          preferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    final ProviderContainer first = await launch();
    first.read(watchlistViewModelProvider.notifier)
      ..changeSort(WatchlistSort.changeRate)
      ..changeSort(WatchlistSort.changeRate);

    final ProviderContainer relaunched = await launch();
    final WatchlistState state = relaunched.read(watchlistViewModelProvider);
    expect((state.sort, state.reversed), (WatchlistSort.changeRate, true));
  });
}
