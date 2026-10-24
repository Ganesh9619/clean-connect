import 'package:flutter_test/flutter_test.dart';
import 'package:sparknest/data/booking_repository.dart';
import 'package:sparknest/data/in_memory_booking_repository.dart';
import 'package:sparknest/data/sample_data.dart';
import 'package:sparknest/models/app_user.dart';
import 'package:sparknest/models/booking.dart';

const client = AppUser(
  id: 'client-1',
  name: sampleClientName,
  email: sampleClientEmail,
  phone: sampleClientPhone,
  role: UserRole.client,
);

void main() {
  late InMemoryBookingRepository repository;

  setUp(() {
    repository = InMemoryBookingRepository(latency: Duration.zero);
  });

  Future<Booking> book() => repository.createBooking(
    client: client,
    condo: sampleCondo,
    package: cleaningPackages.first,
    scheduledAt: DateTime.now().add(const Duration(days: 1)),
    notes: '',
  );

  test('two cleaners accepting at once: exactly one wins', () async {
    final booking = await book();

    final results = await Future.wait([
      repository.acceptBooking(bookingId: booking.id, cleaner: demoCleanerMaria),
      repository.acceptBooking(bookingId: booking.id, cleaner: demoCleanerAna),
    ]);

    final outcomes = results.map((r) => r.outcome).toList();
    expect(outcomes.where((o) => o == AcceptOutcome.accepted), hasLength(1));
    expect(outcomes.where((o) => o == AcceptOutcome.alreadyTaken), hasLength(1));

    final loser = results.firstWhere(
      (r) => r.outcome == AcceptOutcome.alreadyTaken,
    );
    expect(loser.booking?.cleanerId, demoCleanerMaria.id);
  });

  test('cancelled booking cannot be accepted', () async {
    final booking = await book();
    await repository.cancelBooking(bookingId: booking.id, client: client);

    final result = await repository.acceptBooking(
      bookingId: booking.id,
      cleaner: demoCleanerAna,
    );

    expect(result.outcome, AcceptOutcome.unavailable);
  });

  test('client cannot cancel after a cleaner accepted', () async {
    final booking = await book();
    await repository.acceptBooking(
      bookingId: booking.id,
      cleaner: demoCleanerMaria,
    );

    expect(
      () => repository.cancelBooking(bookingId: booking.id, client: client),
      throwsA(isA<BookingException>()),
    );
  });

  test('only the assigned cleaner can complete the job', () async {
    final booking = await book();
    await repository.acceptBooking(
      bookingId: booking.id,
      cleaner: demoCleanerMaria,
    );

    expect(
      () => repository.completeBooking(
        bookingId: booking.id,
        cleaner: demoCleanerAna,
      ),
      throwsA(isA<BookingException>()),
    );
    final done = await repository.completeBooking(
      bookingId: booking.id,
      cleaner: demoCleanerMaria,
    );
    expect(done.status, BookingStatus.completed);
  });

  test('watchBookings emits current state and every change', () async {
    final emissions = <int>[];
    final subscription = repository.watchBookings().listen(
      (bookings) => emissions.add(bookings.length),
    );
    await Future<void>.delayed(Duration.zero);
    await book();
    await Future<void>.delayed(Duration.zero);

    expect(emissions, [0, 1]);
    await subscription.cancel();
  });

  test('price adds a charge per bedroom above two', () {
    final standard = cleaningPackages.first;
    expect(standard.priceFor(1), 80);
    expect(standard.priceFor(2), 80);
    expect(standard.priceFor(4), 110);
  });
}
