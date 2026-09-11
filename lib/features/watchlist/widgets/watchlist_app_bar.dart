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
      child: Row(
        children: [
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
              padding: EdgeInsets.symmetric(vertical: dimens.space1),
              child: Row(
                children: [
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
          SizedBox(width: dimens.space4),
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

  @override
  void dispose() {
    _turns.dispose();
    super.dispose();
  }

  void _onTap() {
    _turns.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '새로고침',
      child: InkWell(
        onTap: _onTap,
        radius: 20,
        child: RotationTransition(
          turns: CurvedAnimation(parent: _turns, curve: Curves.easeInOut),
          child: Icon(
            Icons.sync,
            size: context.dimens.iconMd,
            color: context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
