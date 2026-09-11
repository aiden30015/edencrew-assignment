import 'package:edencrew_assignment_starter/data/repository/fake_stock_repository.dart';
import 'package:edencrew_assignment_starter/data/repository/stock_repository.dart';
import 'package:edencrew_assignment_starter/main.dart';
import 'package:edencrew_assignment_starter/shared/state/favorites_notifier.dart';
import 'package:edencrew_assignment_starter/shared/state/preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('관심 행을 왼쪽으로 밀면 해제되고 토스트가 뜬다', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      FavoritesNotifier.storageKey: <String>['005930', '000660'],
    });
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stockRepositoryProvider.overrideWithValue(
            FakeStockRepository(latency: Duration.zero),
          ),
          preferencesProvider.overrideWithValue(preferences),
        ],
        child: const EdencrewAssignmentApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('삼성전자'), findsOneWidget);

    await tester.drag(find.text('삼성전자'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('삼성전자'), findsNothing);
    expect(find.text('SK하이닉스'), findsOneWidget);
    expect(find.text('관심이 해제되었습니다'), findsOneWidget);
    expect(preferences.getStringList(FavoritesNotifier.storageKey), <String>[
      '000660',
    ]);

    // 새로고침 버튼은 눌렀을 때 한 바퀴 돈다.
    await tester.tap(find.byTooltip('새로고침'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final RotationTransition rotation = tester.widget(
      find.ancestor(
        of: find.byIcon(Icons.sync),
        matching: find.byType(RotationTransition),
      ),
    );
    expect(rotation.turns.value, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
  });
}
