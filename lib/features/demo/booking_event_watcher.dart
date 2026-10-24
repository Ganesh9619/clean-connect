import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/format.dart';
import '../../data/booking_repository.dart';
import '../../models/app_user.dart';
import '../../models/booking.dart';
import '../../session/session.dart';

/// Turns booking changes into push-style banners for this device. In
/// production these come from FCM, sent by a Cloud Function on the same
/// booking events.
class BookingEventWatcher extends StatefulWidget {
  const BookingEventWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<BookingEventWatcher> createState() => _BookingEventWatcherState();
}

class _BookingEventWatcherState extends State<BookingEventWatcher> {
  StreamSubscription<List<Booking>>? _subscription;
  Map<String, BookingStatus>? _previous;

  @override
  void initState() {
    super.initState();
    _subscription = context.read<BookingRepository>().watchBookings().listen(
      _onBookings,
    );
  }

  void _onBookings(List<Booking> bookings) {
    final previous = _previous;
    _previous = {for (final b in bookings) b.id: b.status};
    if (previous == null) return;

    final session = context.read<Session>();
    final user = session.user;
    if (user == null) return;

    for (final booking in bookings) {
      final before = previous[booking.id];
      if (before == booking.status) continue;

      if (user.role == UserRole.cleaner &&
          session.available &&
          before == null &&
          booking.isOpen) {
        session.showNotification(
          DeviceNotification(
            title: 'New job · ${money(booking.cleanerPayout)} payout',
            body:
                '${booking.package.name} at ${booking.condo.publicLabel}, ${formatSlot(booking.scheduledAt)}. Tap Accept before someone else does.',
          ),
        );
      }

      if (user.role == UserRole.client && booking.clientId == user.id) {
        if (booking.status == BookingStatus.accepted) {
          session.showNotification(
            DeviceNotification(
              title: 'Cleaner confirmed',
              body:
                  '${booking.cleanerName} accepted your ${booking.package.name} for ${formatSlot(booking.scheduledAt)}.',
            ),
          );
        } else if (booking.status == BookingStatus.completed) {
          session.showNotification(
            DeviceNotification(
              title: 'Your condo is sparkling',
              body:
                  '${booking.cleanerName} marked your ${booking.package.name} as completed.',
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
