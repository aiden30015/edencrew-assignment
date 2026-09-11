import 'package:edencrew_assignment_starter/data/repository/fake_stock_repository.dart';
import 'package:edencrew_assignment_starter/data/repository/stock_repository.dart';
import 'package:edencrew_assignment_starter/features/watchlist/models/watchlist_sort.dart';
import 'package:edencrew_assignment_starter/features/watchlist/watchlist_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
