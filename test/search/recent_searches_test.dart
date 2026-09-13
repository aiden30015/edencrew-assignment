import 'package:edencrew_assignment_starter/data/repository/stock_repository.dart';
import 'package:edencrew_assignment_starter/features/search/recent_searches_notifier.dart';
import 'package:edencrew_assignment_starter/main.dart';
import 'package:edencrew_assignment_starter/shared/state/preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/fake_stock_repository.dart';

void main() {
  test('최신이 앞, 최대 5개, 같은 검색어는 맨 앞으로 올리고 기기에 저장한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[preferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    final RecentSearchesNotifier recent = container.read(
      recentSearchesProvider.notifier,
    );

    for (final String q in <String>['a', 'b', 'c', 'd', 'e', 'f', 'c', '  ']) {
      recent.add(q);
    }

    expect(container.read(recentSearchesProvider), <String>[
      'c',
      'f',
      'e',
      'd',
      'b',
    ]);
    recent.remove('e');
    expect(
      preferences.getStringList(RecentSearchesNotifier.storageKey),
      <String>['c', 'f', 'd', 'b'],
    );
  });

  testWidgets('검색 결과를 누르면 검색어가 기록되고, 검색 전 화면에서 다시 검색하거나 지울 수 있다', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          stockRepositoryProvider.overrideWithValue(
            FakeStockRepository(latency: Duration.zero),
          ),
          preferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
        ],
        child: const EdencrewAssignmentApp(),
      ),
    );
    await tester.tap(find.text('검색'));
    await tester.pumpAndSettle();
    expect(find.text('종목을 검색해 보세요'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '카카');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('카카오').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('검색어 지우기'));
    await tester.pumpAndSettle();
    expect(find.text('최근 검색어'), findsOneWidget);
    expect(find.text('카카'), findsOneWidget);

    await tester.tap(find.text('카카'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.textContaining('카카오'), findsWidgets);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('최근 검색어 삭제'));
    await tester.pumpAndSettle();
    expect(find.text('최근 검색어'), findsNothing);
    expect(find.text('종목을 검색해 보세요'), findsOneWidget);
  });
}
