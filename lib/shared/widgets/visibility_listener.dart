import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// 화면이 실제로 보이는지 바뀔 때 알려준다. 처음에는 보이는 상태로 보고, 바뀔 때만 onChanged를 부른다.
// - 다른 탭이 선택됐거나 위에 다른 화면이 올라오면 TickerMode가 꺼진다.
// - 앱이 백그라운드로 가면 AppLifecycleState가 hidden/paused가 된다.
class VisibilityListener extends StatefulWidget {
  const VisibilityListener({
    super.key,
    required this.onChanged,
    required this.child,
  });

  final ValueChanged<bool> onChanged;
  final Widget child;

  @override
  State<VisibilityListener> createState() => _VisibilityListenerState();
}

class _VisibilityListenerState extends State<VisibilityListener> {
  late final AppLifecycleListener _lifecycle;
  ValueListenable<TickerModeData>? _tickerMode;
  bool _foreground = true;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onStateChange: (AppLifecycleState state) {
        _foreground =
            state == AppLifecycleState.resumed ||
            state == AppLifecycleState.inactive;
        _update();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ValueListenable<TickerModeData> tickerMode =
        TickerMode.getValuesNotifier(context);
    if (tickerMode == _tickerMode) return;
    _tickerMode?.removeListener(_update);
    _tickerMode = tickerMode..addListener(_update);
    _update();
  }

  void _update() {
    final bool visible = (_tickerMode?.value.enabled ?? true) && _foreground;
    if (visible == _visible) return;
    _visible = visible;
    widget.onChanged(visible);
  }

  @override
  void dispose() {
    _tickerMode?.removeListener(_update);
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
