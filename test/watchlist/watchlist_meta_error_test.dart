import 'package:edencrew_assignment_starter/data/repository/stock_repository.dart';
import 'package:edencrew_assignment_starter/features/watchlist/watchlist_view_model.dart';
import 'package:edencrew_assignment_starter/shared/state/favorites_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/fake_stock_repository.dart';

void main() {
  test('종목 정보를 못 받은 종목을 해제하면 오류 배너가 사라진다', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        stockRepositoryProvider.overrideWithValue(
          FakeStockRepository(latency: Duration.zero),
        ),
      ],
    );
    addTearDown(container.dispose);

    bool hasError() => container.read(watchlistViewModelProvider).hasError;
    container.read(watchlistViewModelProvider);
    final FavoritesNotifier favorites = container.read(
      favoritesProvider.notifier,
    );

    // 999999는 가짜 저장소에 없는 종목이라 메타 요청이 실패한다.
    favorites
      ..toggle('999999')
      ..toggle('005930');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(hasError(), isTrue);

    favorites.toggle('999999');
    expect(hasError(), isFalse);

    // 다시 시도해도 남은 종목은 모두 정상이라 배너가 다시 뜨지 않는다.
    await container.read(watchlistViewModelProvider.notifier).refresh();
    expect(hasError(), isFalse);
  });
}
