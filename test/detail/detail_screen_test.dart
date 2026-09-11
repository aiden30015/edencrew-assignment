import 'package:edencrew_assignment_starter/data/repository/stock_repository.dart';
import 'package:edencrew_assignment_starter/features/detail/detail_screen.dart';
import 'package:edencrew_assignment_starter/features/detail/widgets/candle_chart.dart';
import 'package:edencrew_assignment_starter/features/detail/widgets/daily_price_table.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/fake_stock_repository.dart';

void main() {
  testWidgets('상세 화면이 그려지고 1년 탭으로 바꿔도 레이아웃이 깨지지 않는다', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stockRepositoryProvider.overrideWithValue(
            FakeStockRepository(latency: Duration.zero),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const DetailScreen(symbol: '448730'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('일별 시세'), findsOneWidget);

    // 차트를 길게 누르고 있으면 크로스헤어 툴팁, 떼면 사라진다.
    final TestGesture press = await tester.startGesture(
      tester.getCenter(find.byType(CandleChart)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(Table), findsOneWidget);
    await press.moveBy(const Offset(-100, 0));
    await tester.pump();
    expect(find.byType(Table), findsOneWidget);
    await press.up();
    await tester.pump();
    expect(find.byType(Table), findsNothing);

    // 일별 시세 표는 10행부터, 끝까지 스크롤하면 기간(1개월 = 20행)까지만 더 펼친다.
    int tableRows() => tester
        .widget<DailyPriceTable>(find.byType(DailyPriceTable))
        .rows
        .length;
    expect(tableRows(), 10);
    for (int i = 0; i < 3; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
      await tester.pumpAndSettle();
    }
    expect(tableRows(), 20);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 3000));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1년'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();
  });
}
