import 'package:edencrew_assignment_starter/app/widgets/bottom_nav_bar.dart';
import 'package:edencrew_assignment_starter/features/detail/detail_screen.dart';
import 'package:edencrew_assignment_starter/features/detail/widgets/candle_chart.dart';
import 'package:edencrew_assignment_starter/main.dart';
import 'package:edencrew_assignment_starter/shared/state/preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 실제 기기(에뮬레이터)에서 실제 네이버 응답으로 앱 전체 흐름을 확인하는 종합 테스트.
// 시세 숫자는 매번 달라지므로 값이 아니라 화면 상태와 표기 형식, 개수만 확인한다.
//
// 실행: fvm flutter test integration_test -d <기기 id>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder inNav(String label) => find.descendant(
    of: find.byType(BottomNavBar),
    matching: find.text(label),
  );
  Finder inDetail(Finder finder) =>
      find.descendant(of: find.byType(DetailScreen), matching: finder);

  // 네트워크 응답을 기다린다. 제한 시간 안에 나타나지 않으면 실패.
  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final DateTime end = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) fail('$timeout 안에 나타나지 않음: $finder');
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpUntilGone(WidgetTester tester, Finder finder) async {
    final DateTime end = DateTime.now().add(const Duration(seconds: 30));
    while (finder.evaluate().isNotEmpty) {
      if (DateTime.now().isAfter(end)) fail('사라지지 않음: $finder');
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  // 화면 전환 · 바텀시트 애니메이션이 끝날 때까지.
  Future<void> settle(WidgetTester tester) =>
      tester.pump(const Duration(milliseconds: 600));

  testWidgets('검색에서 관심 등록 → 관심 목록 · 정렬 → 상세 기간 전환 · 관심 해제가 세 화면에 함께 반영된다', (
    WidgetTester tester,
  ) async {
    // 기기에 저장된 관심 목록과 섞이지 않도록 빈 저장소로 시작한다.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(preferences)],
        child: const EdencrewAssignmentApp(),
      ),
    );
    await tester.pump();

    // 1. 첫 실행은 관심 빈 상태.
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);

    // 2. 검색 탭: 입력 전 초기 상태.
    await tester.tap(inNav('검색'));
    await tester.pump();
    expect(find.text('종목을 검색해 보세요'), findsOneWidget);

    // 3. 결과가 없으면 입력한 검색어가 문구에 들어가고, 지우면 초기 상태로 돌아간다.
    const String noResult = '존재하지않는종목';
    await tester.enterText(find.byType(TextField), noResult);
    await pumpUntil(tester, find.textContaining('일치하는 검색 결과를 찾지 못했습니다'));
    expect(find.textContaining("'$noResult'와"), findsOneWidget);

    await tester.tap(find.byTooltip('검색어 지우기'));
    await tester.pump();
    expect(find.text('종목을 검색해 보세요'), findsOneWidget);

    // 4. 삼성전자 검색 → 별을 눌러 관심 등록 → 토스트.
    await tester.enterText(find.byType(TextField), '삼성전자');
    final Finder searchRow = find.byKey(
      const ValueKey<String>('domestic:005930'),
    );
    await pumpUntil(tester, searchRow);
    expect(
      find.descendant(of: searchRow, matching: find.text('005930 · 코스피')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(of: searchRow, matching: find.byTooltip('관심 등록')),
    );
    await tester.pump();
    expect(find.text('관심이 등록되었습니다'), findsOneWidget);
    expect(
      find.descendant(of: searchRow, matching: find.byTooltip('관심 해제')),
      findsOneWidget,
    );

    // 5. 관심 탭: 등록한 종목이 보이고, 실제 시세가 들어오면 등락률이 표시된다.
    await tester.tap(inNav('관심'));
    await tester.pump();
    final Finder watchRow = find.byKey(const ValueKey<String>('005930'));
    await pumpUntil(
      tester,
      find.descendant(of: watchRow, matching: find.text('삼성전자')),
    );
    await pumpUntil(
      tester,
      find.descendant(of: watchRow, matching: find.textContaining('%)')),
    );
    expect(
      find.descendant(of: watchRow, matching: find.text('005930 · 코스피')),
      findsOneWidget,
    );

    // 6. 정렬 칩 → 바텀시트 → 현재가순. 칩 문구가 바뀐다.
    await tester.tap(find.text('가나다순'));
    await settle(tester);
    await tester.tap(find.text('현재가순'));
    await settle(tester);
    expect(find.text('현재가순'), findsOneWidget);
    expect(find.text('가나다순'), findsNothing);

    // 7. 행을 눌러 상세로. 1개월은 20거래일.
    await tester.tap(watchRow);
    await settle(tester);
    await pumpUntil(tester, inDetail(find.text('1개월')));
    expect(inDetail(find.text('005930 · 코스피')), findsOneWidget);
    expect(
      tester.widget<CandleChart>(find.byType(CandleChart)).candles,
      hasLength(20),
    );

    // 8. 1년 탭: 필요한 페이지를 더 받아 245거래일로 바뀐다. 표 날짜는 MM.DD.
    await tester.tap(inDetail(find.text('1년')));
    await tester.pump();
    await pumpUntilGone(
      tester,
      find.descendant(
        of: find.byType(CandleChart),
        matching: find.byType(CircularProgressIndicator),
      ),
    );
    expect(
      tester.widget<CandleChart>(find.byType(CandleChart)).candles,
      hasLength(245),
    );
    expect(inDetail(find.text('날짜')), findsOneWidget);
    expect(
      inDetail(find.textContaining(RegExp(r'^\d{2}\.\d{2}$'))),
      findsWidgets,
    );

    // 9. 상세에서 관심 해제 → 뒤로 가면 관심 목록이 빈 상태가 된다.
    await tester.tap(inDetail(find.byTooltip('관심 해제')));
    await tester.pump();
    expect(inDetail(find.byTooltip('관심 등록')), findsOneWidget);

    await tester.tap(find.byTooltip('뒤로 가기'));
    await settle(tester);
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);

    // 10. 검색 탭에 남아 있는 같은 종목의 별 아이콘도 해제 상태로 바뀌어 있다.
    await tester.tap(inNav('검색'));
    await tester.pump();
    expect(
      find.descendant(of: searchRow, matching: find.byTooltip('관심 등록')),
      findsOneWidget,
    );
  });
}
