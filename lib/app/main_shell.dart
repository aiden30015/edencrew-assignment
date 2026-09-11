import 'package:flutter/material.dart';

import '../features/search/search_screen.dart';
import '../features/watchlist/watchlist_screen.dart';
import 'widgets/bottom_nav_bar.dart';

// 관심 / 검색 하단 탭을 가진 최상위 화면.
// IndexedStack으로 두 탭을 모두 살려 둬서 탭을 오가도 검색어 · 스크롤 위치가 유지된다.
// 탭 인덱스는 이 화면에서만 쓰는 UI 상태라 Riverpod 대신 State에 둔다.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const List<BottomNavItem> _items = <BottomNavItem>[
    BottomNavItem(
      label: '관심',
      icon: Icons.star_outline_rounded,
      activeIcon: Icons.star_rounded,
    ),
    BottomNavItem(label: '검색', icon: Icons.search, activeIcon: Icons.search),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 안 보이는 탭은 TickerMode를 꺼서 애니메이션과 시세 자동 갱신을 멈춘다.
      body: IndexedStack(
        index: _index,
        children: [
          TickerMode(enabled: _index == 0, child: const WatchlistScreen()),
          TickerMode(enabled: _index == 1, child: const SearchScreen()),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        items: _items,
        currentIndex: _index,
        onTap: (int index) => setState(() => _index = index),
      ),
    );
  }
}
