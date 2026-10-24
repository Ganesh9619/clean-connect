import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/condo.dart';

class DeviceNotification {
  const DeviceNotification({required this.title, required this.body});

  final String title;
  final String body;
}

/// State for one signed-in device: who is using it, their condo, cleaner
/// availability, and the push-style banner currently on screen.
class Session extends ChangeNotifier {
  Session({required this.preferredRole, AppUser? user})
    : _initialUser = user,
      _user = user;

  final UserRole preferredRole;
  final AppUser? _initialUser;

  AppUser? _user;
  Condo? _condo;
  bool _available = true;
  int _nextUserId = 1;
  Timer? _notificationTimer;

  final ValueNotifier<DeviceNotification?> notification = ValueNotifier(null);

  AppUser? get user => _user;
  Condo? get condo => _condo;
  bool get available => _available;

  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _user = AppUser(
      id: '${role.name}-${DateTime.now().microsecondsSinceEpoch}-${_nextUserId++}',
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: role,
    );
    notifyListeners();
  }

  void saveCondo(Condo condo) {
    _condo = condo;
    notifyListeners();
  }

  void setAvailable(bool value) {
    _available = value;
    notifyListeners();
  }

  void showNotification(DeviceNotification value) {
    _notificationTimer?.cancel();
    notification.value = value;
    _notificationTimer = Timer(const Duration(seconds: 5), dismissNotification);
  }

  void dismissNotification() {
    _notificationTimer?.cancel();
    notification.value = null;
  }

  void reset() {
    dismissNotification();
    _user = _initialUser;
    _condo = null;
    _available = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    notification.dispose();
    super.dispose();
  }
}
