import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.height,
    required this.child,
    this.padding,
  });

  final double height;
  final Widget child;

  // 기본은 좌우 space4. 끝에 놓인 아이콘 버튼이 이 여백까지 누르는 영역으로 쓰려면 해당 쪽을 0으로 준다.
  final EdgeInsetsGeometry? padding;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.surfaceBase,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height,
          child: Padding(
            padding:
                padding ??
                EdgeInsets.symmetric(horizontal: context.dimens.space4),
            child: child,
          ),
        ),
      ),
    );
  }
}

// 아이콘은 시안 크기(iconMd)로 그리고, 누르는 영역은 헤더 높이 전체와 [padding]까지 넓힌다.
// 20 × 20 아이콘만 눌리면 조금만 벗어나도 반응하지 않는다.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
    this.padding = EdgeInsets.zero,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: SizedBox(
          height: double.infinity,
          child: Padding(
            padding: padding,
            child: Icon(icon, size: context.dimens.iconMd, color: color),
          ),
        ),
      ),
    );
  }
}
