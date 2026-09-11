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
}
