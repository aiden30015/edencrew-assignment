import 'package:edencrew_assignment_starter/data/repository/stock_repository.dart';
import 'package:edencrew_assignment_starter/features/detail/detail_screen.dart';
import 'package:edencrew_assignment_starter/features/detail/widgets/candle_chart.dart';
import 'package:edencrew_assignment_starter/features/detail/widgets/daily_price_table.dart';
import 'package:edencrew_assignment_starter/features/detail/widgets/detail_app_bar.dart';
import 'package:edencrew_assignment_starter/app/app.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/misc.dart';

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
        overrides: <Override>[
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

  testWidgets('글자 크기 최대(1.3배)에서도 긴 가격 · 종목명이 넘치지 않는다', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue =
        EdencrewAssignmentApp.maxTextScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    // 207940은 가격이 7자리(1,043,000)인 종목.
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          stockRepositoryProvider.overrideWithValue(
            FakeStockRepository(latency: Duration.zero),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const DetailScreen(symbol: '207940'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1,043,000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('헤더의 뒤로 가기 · 별은 48 이상 눌리고, 아이콘 위치는 시안 그대로', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          stockRepositoryProvider.overrideWithValue(
            FakeStockRepository(latency: Duration.zero),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const DetailScreen(symbol: '005930'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Size back = tester.getSize(find.byTooltip('뒤로 가기'));
    expect(back.width, greaterThanOrEqualTo(kMinInteractiveDimension));
    expect(back.height, greaterThanOrEqualTo(kMinInteractiveDimension));
    expect(
      tester.getSize(find.byTooltip('관심 등록')),
      const Size.square(kMinInteractiveDimension),
    );

    // 아이콘은 좌우 여백 16, 종목명은 뒤로 가기 아이콘 + 간격 12 뒤(48)에서 시작.
    expect(tester.getTopLeft(find.byIcon(Icons.arrow_back)).dx, 16);
    expect(
      tester.getTopRight(find.byIcon(Icons.star_outline_rounded)).dx,
      393 - 16,
    );
    expect(
      tester
          .getTopLeft(
            find.descendant(
              of: find.byType(DetailAppBar),
              matching: find.text('삼성전자'),
            ),
          )
          .dx,
      48,
    );
  });

  testWidgets('상세 화면에서 별을 누르면 등록 · 해제 토스트가 뜬다', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          stockRepositoryProvider.overrideWithValue(
            FakeStockRepository(latency: Duration.zero),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          navigatorKey: navigator,
          home: const SizedBox.shrink(),
        ),
      ),
    );
    // 앱과 같은 경로(DetailScreen.route)로 연다.
    navigator.currentState!.push(DetailScreen.route('005930'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('관심 등록'));
    await tester.pump();
    expect(find.text('관심이 등록되었습니다'), findsOneWidget);

    await tester.tap(find.byTooltip('관심 해제'));
    await tester.pump();
    expect(find.text('관심이 해제되었습니다'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
