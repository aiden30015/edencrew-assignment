import 'package:edencrew_assignment_starter/shared/widgets/app_toast.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('연속으로 띄우면 대기열 없이 바로 바뀌고, 2초 뒤 사라진다', (WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext c) {
              context = c;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    showAppToast(context, message: '첫 번째');
    await tester.pump();
    showAppToast(context, message: '두 번째');
    await tester.pumpAndSettle();

    expect(find.text('첫 번째'), findsNothing);
    expect(find.text('두 번째'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('두 번째'), findsNothing);
  });
}
