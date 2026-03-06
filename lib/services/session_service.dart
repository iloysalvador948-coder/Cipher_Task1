import 'dart:async';

import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class SessionService extends ChangeNotifier {
  Timer? _timeoutTimer;
  Timer? _warningTimer;

  bool _locked = true;
  bool _warningActive = false;

  bool get isLocked => _locked;
  bool get isWarningActive => _warningActive;

  Future<void> Function()? onTimeoutLock;
  Future<void> Function()? onWarningStart;
  Future<void> Function()? onWarningDismiss;

  void unlockSession() {
    _locked = false;
    _dismissWarning();
    _restartTimers();
    notifyListeners();
  }

  void lockSession() {
    _locked = true;
    _timeoutTimer?.cancel();
    _warningTimer?.cancel();
    _dismissWarning();
    notifyListeners();
  }

  void handleUserInteraction() {
    if (_locked) return;

    _dismissWarning();
    _restartTimers();
  }

  void _restartTimers() {
    _timeoutTimer?.cancel();
    _warningTimer?.cancel();

    final totalSeconds = Constants.inactivityTimeoutSeconds;
    final warningAfterSeconds =
        totalSeconds - Constants.sessionWarningSeconds;

    if (warningAfterSeconds > 0) {
      _warningTimer = Timer(
        Duration(seconds: warningAfterSeconds),
        _triggerWarning,
      );
    }

    _timeoutTimer = Timer(
      Duration(seconds: totalSeconds),
      () {
        lockSession();
        onTimeoutLock?.call();
      },
    );
  }

  void _triggerWarning() {
    if (_locked || _warningActive) return;

    _warningActive = true;
    notifyListeners();
    onWarningStart?.call();
  }

  void _dismissWarning() {
    if (!_warningActive) return;

    _warningActive = false;
    notifyListeners();
    onWarningDismiss?.call();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _warningTimer?.cancel();
    super.dispose();
  }
}