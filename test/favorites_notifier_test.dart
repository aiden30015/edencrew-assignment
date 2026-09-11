import 'package:edencrew_assignment_starter/shared/state/favorites_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> launch() async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('처음 실행하면 관심 목록이 비어 있고, 등록 · 해제가 재실행 후에도 남는다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final ProviderContainer first = await launch();
    expect(first.read(favoritesProvider), isEmpty);

    first.read(favoritesProvider.notifier)
      ..toggle('005930')
      ..toggle('000660')
      ..toggle('005930');

    final ProviderContainer relaunched = await launch();
    expect(relaunched.read(favoritesProvider), <String>['000660']);
  });
}
