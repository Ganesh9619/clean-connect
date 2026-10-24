import 'dart:async';

import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/cleaning_package.dart';
import '../models/condo.dart';
import 'booking_repository.dart';
import 'sample_data.dart';

/// Demo backend that keeps bookings in memory and simulates network latency.
class InMemoryBookingRepository implements BookingRepository {
  InMemoryBookingRepository({
    this.latency = const Duration(milliseconds: 600),
    List<CleaningPackage> packages = cleaningPackages,
  }) : _packages = List.unmodifiable(packages);

  final Duration latency;
  final List<CleaningPackage> _packages;
  final Map<String, Booking> _bookings = {};
  final StreamController<List<Booking>> _changes =
      StreamController<List<Booking>>.broadcast();
  int _nextId = 1;

  List<Booking> _snapshot() {
    final list = _bookings.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  void _emit() => _changes.add(_snapshot());

  Future<void> _network() => Future<void>.delayed(latency);

  /// Clears every booking. Used by the demo's Reset button.
  void reset() {
    _bookings.clear();
    _emit();
  }

  @override
  Future<List<CleaningPackage>> fetchPackages() async {
    await _network();
    return _packages;
  }

  @override
  Stream<List<Booking>> watchBookings() {
    late final StreamController<List<Booking>> controller;
    StreamSubscription<List<Booking>>? subscription;
    controller = StreamController<List<Booking>>(
      onListen: () {
        controller.add(_snapshot());
        subscription = _changes.stream.listen(controller.add);
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<Booking> createBooking({
    required AppUser client,
    required Condo condo,
    required CleaningPackage package,
    required DateTime scheduledAt,
    required String notes,
  }) async {
    if (client.role != UserRole.client) {
      throw const BookingException('Only clients can create bookings.');
    }
    await _network();
    if (scheduledAt.isBefore(DateTime.now())) {
      throw const BookingException('Pick a time in the future.');
    }
    final booking = Booking(
      id: 'BK-${(1000 + _nextId++)}',
      clientId: client.id,
      clientName: client.name,
      clientPhone: client.phone,
      condo: condo,
      package: package,
      scheduledAt: scheduledAt,
      notes: notes.trim(),
      createdAt: DateTime.now(),
    );
    _bookings[booking.id] = booking;
    _emit();
    return booking;
  }

  @override
  Future<AcceptResult> acceptBooking({
    required String bookingId,
    required AppUser cleaner,
  }) async {
    await _network();
    // No await between the check and the write, so concurrent calls cannot
    // both see the booking as open.
    final current = _bookings[bookingId];
    if (current == null || current.status == BookingStatus.cancelled) {
      return AcceptResult(AcceptOutcome.unavailable, current);
    }
    if (current.status != BookingStatus.requested) {
      return AcceptResult(AcceptOutcome.alreadyTaken, current);
    }
    final accepted = current.copyWith(
      status: BookingStatus.accepted,
      cleanerId: cleaner.id,
      cleanerName: cleaner.name,
      acceptedAt: DateTime.now(),
    );
    _bookings[bookingId] = accepted;
    _emit();
    return AcceptResult(AcceptOutcome.accepted, accepted);
  }

  @override
  Future<Booking> completeBooking({
    required String bookingId,
    required AppUser cleaner,
  }) async {
    await _network();
    final current = _bookings[bookingId];
    if (current == null ||
        current.status != BookingStatus.accepted ||
        current.cleanerId != cleaner.id) {
      throw const BookingException('This job can no longer be completed.');
    }
    final completed = current.copyWith(
      status: BookingStatus.completed,
      completedAt: DateTime.now(),
    );
    _bookings[bookingId] = completed;
    _emit();
    return completed;
  }

  @override
  Future<Booking> cancelBooking({
    required String bookingId,
    required AppUser client,
  }) async {
    await _network();
    final current = _bookings[bookingId];
    if (current == null || current.clientId != client.id) {
      throw const BookingException('Booking not found.');
    }
    if (current.status != BookingStatus.requested) {
      throw const BookingException(
        'A cleaner already accepted this booking. Contact them to reschedule.',
      );
    }
    final cancelled = current.copyWith(status: BookingStatus.cancelled);
    _bookings[bookingId] = cancelled;
    _emit();
    return cancelled;
  }

  Future<void> dispose() => _changes.close();
}
