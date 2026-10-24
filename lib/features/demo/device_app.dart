import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/app_user.dart';
import '../../session/session.dart';
import '../auth/sign_up_screen.dart';
import '../cleaner/cleaner_home_screen.dart';
import '../client/client_home_screen.dart';
import '../client/condo_form_screen.dart';
import 'booking_event_watcher.dart';
import 'notification_banner.dart';

/// One phone's worth of app: its own navigation, snackbars and session,
/// sharing the backend with the other devices.
class DeviceApp extends StatelessWidget {
  const DeviceApp({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<Session>.value(
      value: session,
      child: MaterialApp(
        title: 'SparkNest',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        builder: (context, child) => BookingEventWatcher(
          child: Stack(
            children: [
              ?child,
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: NotificationBanner(session: session),
              ),
            ],
          ),
        ),
        home: const _SessionRouter(),
      ),
    );
  }
}

class _SessionRouter extends StatelessWidget {
  const _SessionRouter();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final user = session.user;
    final Widget screen;
    if (user == null) {
      screen = const SignUpScreen();
    } else if (user.role == UserRole.cleaner) {
      screen = CleanerHomeScreen(key: ValueKey(user.id));
    } else if (session.condo == null) {
      screen = const CondoFormScreen(isOnboarding: true);
    } else {
      screen = ClientHomeScreen(key: ValueKey(user.id));
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(key: ValueKey(screen.runtimeType), child: screen),
    );
  }
}
