import 'package:edencrew_assignment_starter/app/widgets/bottom_nav_bar.dart';
import 'package:edencrew_assignment_starter/data/repository/stock_repository.dart';
import 'package:edencrew_assignment_starter/features/detail/detail_screen.dart';
import 'package:edencrew_assignment_starter/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/misc.dart';

import 'mocks/fake_stock_repository.dart';

// integration_test의 동기화 흐름을 네트워크 없이 가짜 저장소로 확인한다.
void main() {
  Finder inNav(String label) => find.descendant(
    of: find.byType(BottomNavBar),
    matching: find.text(label),
  );
  Finder inDetail(Finder finder) =>
      find.descendant(of: find.byType(DetailScreen), matching: finder);

  testWidgets('검색에서 등록 → 관심 목록에 추가 → 상세에서 해제 → 목록 · 검색 별이 함께 바뀐다', (
    WidgetTester tester,
  ) async {
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
    await tester.pump();
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);

    // 검색에서 별을 눌러 등록.
    await tester.tap(inNav('검색'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '삼성전자');
    await tester.pumpAndSettle();
    final Finder searchRow = find.byKey(
      const ValueKey<String>('domestic:005930'),
    );
    await tester.tap(
      find.descendant(of: searchRow, matching: find.byTooltip('관심 등록')),
    );
    await tester.pump();
    expect(
      find.descendant(of: searchRow, matching: find.byTooltip('관심 해제')),
      findsOneWidget,
    );

    // 관심 목록에 행이 생긴다.
    await tester.tap(inNav('관심'));
    await tester.pumpAndSettle();
    final Finder watchRow = find.byKey(const ValueKey<String>('005930'));
    expect(
      find.descendant(of: watchRow, matching: find.text('삼성전자')),
      findsOneWidget,
    );

    // 상세 별도 등록 상태이고, 해제하면 바로 바뀐다.
    await tester.tap(watchRow);
    await tester.pumpAndSettle();
    await tester.tap(inDetail(find.byTooltip('관심 해제')));
    await tester.pump();
    expect(inDetail(find.byTooltip('관심 등록')), findsOneWidget);

    // 돌아오면 목록은 빈 상태, 검색 결과의 별도 해제 상태.
    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);

    await tester.tap(inNav('검색'));
    await tester.pump();
    expect(
      find.descendant(of: searchRow, matching: find.byTooltip('관심 등록')),
      findsOneWidget,
    );

    // 토스트 타이머(2초)가 끝날 때까지.
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
