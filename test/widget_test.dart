import 'package:edencrew_assignment_starter/app/widgets/bottom_nav_bar.dart';
import 'package:edencrew_assignment_starter/data/repository/stock_repository.dart';
import 'package:edencrew_assignment_starter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/misc.dart';

import 'mocks/fake_stock_repository.dart';

void main() {
  testWidgets('하단 탭으로 관심 / 검색을 전환한다', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          stockRepositoryProvider.overrideWithValue(
            FakeStockRepository(latency: Duration.zero),
          ),
        ],
        child: const EdencrewAssignmentApp(),
      ),
    );

    Finder inNav(Finder f) =>
        find.descendant(of: find.byType(BottomNavBar), matching: f);

    expect(inNav(find.byIcon(Icons.star_rounded)), findsOneWidget);

    await tester.tap(inNav(find.text('검색')));
    await tester.pump();

    expect(inNav(find.byIcon(Icons.star_outline_rounded)), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets('기기 글자 크기가 커도 앱 안에서는 1.3배까지만 키운다', (WidgetTester tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          stockRepositoryProvider.overrideWithValue(
            FakeStockRepository(latency: Duration.zero),
          ),
        ],
        child: const EdencrewAssignmentApp(),
      ),
    );

    final BuildContext context = tester.element(find.byType(BottomNavBar));
    expect(
      MediaQuery.textScalerOf(context).scale(10),
      10 * EdencrewAssignmentApp.maxTextScale,
    );
  });
}
