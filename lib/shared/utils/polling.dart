import 'dart:async';

import 'package:flutter/foundation.dart';

// 실시간 시세 자동 갱신. 네이버 실시간 시세는 SSE · WebSocket이 없는 폴링 API라서
// 응답이 올 때마다 서버가 준 간격(pollingInterval)만큼 기다렸다가 다시 조회한다.
// 화면이 안 보이거나(active = false) 장이 마감되면 다음 조회를 예약하지 않는다.
class Polling {
  Polling(this._onTick);

  final VoidCallback _onTick;

  Timer? _timer;

  // 화면은 처음 만들어질 때 보이는 상태라서 true로 시작한다.
  bool _active = true;

  bool get isActive => _active;

  // 가려졌다가 다시 보이면 기다리지 않고 바로 한 번 조회한다.
  void setActive(bool active) {
    if (active == _active) return;
    _active = active;
    _timer?.cancel();
    if (active) _onTick();
  }

  // 조회가 끝날 때마다 호출한다.
  void scheduleNext(Duration interval, {required bool marketOpen}) {
    _timer?.cancel();
    if (_active && marketOpen) _timer = Timer(interval, _onTick);
  }

  void dispose() => _timer?.cancel();
}
