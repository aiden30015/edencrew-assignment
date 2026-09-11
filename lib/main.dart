import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/main_shell.dart';
import 'theme/theme.dart';

void main() {
  runApp(const ProviderScope(child: EdencrewAssignmentApp()));
}

class EdencrewAssignmentApp extends StatelessWidget {
  const EdencrewAssignmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '이든크루 평가 과제',
      theme: AppTheme.dark,
      home: const MainShell(),
    );
  }
}
