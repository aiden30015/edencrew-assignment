import 'package:edencrew_assignment_starter/app/widgets/bottom_nav_bar.dart';
import 'package:edencrew_assignment_starter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('하단 탭으로 관심 / 검색을 전환한다', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EdencrewAssignmentApp()),
    );

    Finder inNav(Finder f) =>
        find.descendant(of: find.byType(BottomNavBar), matching: f);

    expect(inNav(find.byIcon(Icons.star_rounded)), findsOneWidget);

    await tester.tap(inNav(find.text('검색')));
    await tester.pump();

    expect(inNav(find.byIcon(Icons.star_outline_rounded)), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 1));
  });
}
