import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

// 관심 등록 · 해제 토스트. 검색 · 관심 · 상세 화면이 같이 쓴다.
void showFavoriteToast(BuildContext context, {required bool added}) {
  showAppToast(
    context,
    message: added ? '관심이 등록되었습니다' : '관심이 해제되었습니다',
    icon: added ? Icons.star_rounded : Icons.star_outline_rounded,
    iconColor: added ? context.colors.favoriteActive : null,
  );
}

// 화면 하단 토스트. 가장 가까운 ToastHost에 띄운다.
void showAppToast(
  BuildContext context, {
  required String message,
  IconData? icon,
  Color? iconColor,
}) {
  context.findAncestorStateOfType<ToastHostState>()?.show(
    message: message,
    icon: icon,
    iconColor: iconColor,
  );
}

// 토스트를 child 위 하단에 쌓아서 보여준다.
// - 최대 3개. 새 토스트가 맨 아래에 붙고, 넘치면 가장 오래된 것부터 바로 지운다.
// - 각자 2초 뒤에 사라지고, 탭하면 바로 닫힌다.
// SnackBar는 한 번에 하나만 보여줄 수 있어서 쌓는 동작을 위해 직접 구현했다.
class ToastHost extends StatefulWidget {
  const ToastHost({super.key, required this.child});

  final Widget child;

  @override
  State<ToastHost> createState() => ToastHostState();
}

class ToastHostState extends State<ToastHost> {
  static const int maxCount = 3;
  static const Duration duration = Duration(seconds: 2);

  final List<_Toast> _toasts = <_Toast>[];
  int _nextId = 0;

  void show({required String message, IconData? icon, Color? iconColor}) {
    final _Toast toast = _Toast(
      id: _nextId++,
      message: message,
      icon: icon,
      iconColor: iconColor,
    );
    toast.timer = Timer(duration, () => _startLeaving(toast));
    setState(() {
      _toasts.add(toast);
      while (_toasts.length > maxCount) {
        _toasts.removeAt(0).timer?.cancel();
      }
    });
  }

  // 사라지는 애니메이션이 끝나면 _remove가 불린다.
  void _startLeaving(_Toast toast) {
    toast.timer?.cancel();
    if (!mounted || !_toasts.contains(toast)) return;
    setState(() => toast.leaving = true);
  }

  void _remove(_Toast toast) {
    if (!mounted) return;
    setState(() => _toasts.remove(toast));
  }

  @override
  void dispose() {
    for (final _Toast toast in _toasts) {
      toast.timer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: dimens.space4,
          right: dimens.space4,
          // 하단 탭 화면에서는 Scaffold가 body를 탭 바 · 키보드 위로 줄이고 여백을 0으로 주므로 그 바로 위,
          // 상세처럼 화면 전체를 감쌀 때는 제스처 바나 키보드 중 더 높은 쪽 위에 뜬다.
          bottom:
              dimens.space3 +
              max(
                MediaQuery.paddingOf(context).bottom,
                MediaQuery.viewInsetsOf(context).bottom,
              ),
          // Scaffold 바깥을 감쌀 때도 글자 스타일이 적용되도록 투명 Material을 둔다.
          // (Material 조상이 없으면 Text에 노란 밑줄이 생긴다)
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final _Toast toast in _toasts)
                  _AnimatedToast(
                    key: ValueKey<int>(toast.id),
                    toast: toast,
                    onTap: () => _startLeaving(toast),
                    onRemoved: () => _remove(toast),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Toast {
  _Toast({
    required this.id,
    required this.message,
    required this.icon,
    required this.iconColor,
  });

  final int id;
  final String message;
  final IconData? icon;
  final Color? iconColor;
  Timer? timer;
  bool leaving = false;
}

// 아래에서 올라오며 나타나고, 사라질 때는 흐려지면서 자리가 줄어든다.
class _AnimatedToast extends StatefulWidget {
  const _AnimatedToast({
    super.key,
    required this.toast,
    required this.onTap,
    required this.onRemoved,
  });

  final _Toast toast;
  final VoidCallback onTap;
  final VoidCallback onRemoved;

  @override
  State<_AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<_AnimatedToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  )..forward();

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void didUpdateWidget(_AnimatedToast oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.toast.leaving && _controller.status != AnimationStatus.reverse) {
      _controller.reverse().whenComplete(widget.onRemoved);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _curve,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(_curve),
          child: Padding(
            padding: EdgeInsets.only(top: context.dimens.space2),
            child: GestureDetector(
              onTap: widget.onTap,
              child: _ToastContent(
                message: widget.toast.message,
                icon: widget.toast.icon,
                iconColor:
                    widget.toast.iconColor ?? context.colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastContent extends StatelessWidget {
  const _ToastContent({
    required this.message,
    required this.icon,
    required this.iconColor,
  });

  static const double _height = 46;

  final String message;
  final IconData? icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final IconData? icon = this.icon;

    return Container(
      height: _height,
      padding: EdgeInsets.symmetric(horizontal: dimens.space4),
      decoration: BoxDecoration(
        color: colors.surfaceOverlay,
        borderRadius: BorderRadius.circular(dimens.radiusLg),
        border: Border.all(
          color: colors.borderSubtle,
          width: dimens.borderHairline,
        ),
      ),
      child: Row(
        spacing: dimens.space2,
        children: [
          if (icon != null) Icon(icon, size: dimens.iconSm, color: iconColor),
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bold13.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
