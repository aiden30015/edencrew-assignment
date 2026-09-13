import 'package:flutter/material.dart';

import '../../../shared/widgets/app_header.dart';
import '../../../theme/theme.dart';
import '../models/watchlist_sort.dart';

class WatchlistAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WatchlistAppBar({
    super.key,
    required this.sort,
    required this.reversed,
    required this.onSortTap,
    required this.onRefresh,
  });

  static const double _height = 52;

  final WatchlistSort sort;

  final bool reversed;
  final VoidCallback onSortTap;
  final VoidCallback onRefresh;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return AppHeader(
      height: _height,
      // 새로고침은 정렬 칩과의 간격 · 오른쪽 여백(space4)을 누르는 영역에 포함한다.
      padding: EdgeInsets.only(left: dimens.space4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '관심',
              style: AppTypography.bold19.copyWith(color: colors.textPrimary),
            ),
          ),
          InkWell(
            onTap: onSortTap,
            borderRadius: BorderRadius.circular(dimens.radiusSm),
            child: Padding(
              // 칩 높이를 44까지 늘려 누르기 쉽게 한다. 글자 위치는 헤더 가운데 그대로.
              padding: EdgeInsets.symmetric(vertical: dimens.space3),
              child: Row(
                children: <Widget>[
                  Text(
                    sort.label,
                    style: AppTypography.bold13.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  Icon(
                    reversed ? Icons.arrow_upward : Icons.arrow_downward,
                    size: dimens.iconMd,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          _RefreshButton(onTap: onRefresh),
        ],
      ),
    );
  }
}

// 누르면 아이콘이 한 바퀴 돌아서 새로고침이 시작됐다는 걸 바로 보여준다.
class _RefreshButton extends StatefulWidget {
  const _RefreshButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turns = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  // build마다 새로 만들면 컨트롤러에 리스너가 계속 쌓여서 한 번만 만든다.
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _turns,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _curve.dispose();
    _turns.dispose();
    super.dispose();
  }

  void _onTap() {
    _turns.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;

    return Tooltip(
      message: '새로고침',
      child: InkResponse(
        onTap: _onTap,
        radius: 20,
        child: SizedBox(
          height: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: dimens.space4),
            child: RotationTransition(
              turns: _curve,
              child: Icon(
                Icons.sync,
                size: dimens.iconMd,
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
