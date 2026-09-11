import 'package:edencrew_assignment_starter/shared/widgets/app_toast.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BuildContext context;

  Future<void> pumpHost(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: ToastHost(
          child: Builder(
            builder: (BuildContext c) {
              context = c;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    ),
  );

  testWidgets('최대 3개까지 쌓이고, 넘치면 가장 오래된 것부터 사라진다', (WidgetTester tester) async {
    await pumpHost(tester);

    for (final String message in <String>['1', '2', '3', '4']) {
      showAppToast(context, message: message);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    // 새 토스트가 맨 아래
    expect(
      tester.getTopLeft(find.text('4')).dy,
      greaterThan(tester.getTopLeft(find.text('3')).dy),
    );
  });

  testWidgets('각자 2초 뒤에 사라지고, 탭하면 바로 닫힌다', (WidgetTester tester) async {
    await pumpHost(tester);

    showAppToast(context, message: '첫 번째');
    await tester.pump(const Duration(seconds: 1));
    showAppToast(context, message: '두 번째');
    await tester.pump(const Duration(milliseconds: 300));

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('첫 번째'), findsNothing);
    expect(find.text('두 번째'), findsOneWidget);

    await tester.tap(find.text('두 번째'));
    await tester.pumpAndSettle();
    expect(find.text('두 번째'), findsNothing);
  });

  // 키보드(높이 300)와 제스처 바(34)가 있는 393 × 852 화면.
  const double screenHeight = 852;
  const double keyboard = 300;
  void withKeyboard(WidgetTester tester) {
    tester.view.physicalSize = const Size(393, screenHeight);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 34);
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.reset);
  }

  Future<double> toastBottom(WidgetTester tester) async {
    showAppToast(context, message: '토스트');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    return tester.getBottomLeft(find.text('토스트')).dy;
  }

  testWidgets('키보드가 올라와 있으면 탭 화면(Scaffold body 안)에서 키보드 위에 뜬다', (
    WidgetTester tester,
  ) async {
    withKeyboard(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ToastHost(
            child: Builder(
              builder: (BuildContext c) {
                context = c;
                return const SizedBox.expand();
              },
            ),
          ),
          bottomNavigationBar: const SizedBox(height: 80),
        ),
      ),
    );

    expect(
      await toastBottom(tester),
      lessThanOrEqualTo(screenHeight - keyboard),
    );
  });

  testWidgets('키보드가 올라와 있으면 상세 화면(Scaffold 바깥)에서도 키보드 위에 뜬다', (
    WidgetTester tester,
  ) async {
    withKeyboard(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ToastHost(
          child: Builder(
            builder: (BuildContext c) {
              context = c;
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      ),
    );

    expect(
      await toastBottom(tester),
      lessThanOrEqualTo(screenHeight - keyboard),
    );
  });
}
