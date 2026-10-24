import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/format.dart';
import '../../data/booking_repository.dart';
import '../../models/booking.dart';
import '../../models/cleaning_package.dart';
import '../../models/condo.dart';
import '../../session/session.dart';
import '../../widgets/common.dart';
import 'book_package_screen.dart';
import 'condo_form_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  late Future<List<CleaningPackage>> _packages;
  late final Stream<List<Booking>> _bookings;

  @override
  void initState() {
    super.initState();
    final repository = context.read<BookingRepository>();
    _packages = repository.fetchPackages();
    _bookings = repository.watchBookings();
  }

  void _reloadPackages() {
    setState(() {
      _packages = context.read<BookingRepository>().fetchPackages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final user = session.user!;
    final condo = session.condo!;
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user.firstName}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InitialsAvatar(name: user.name, radius: 16),
          ),
        ],
      ),
      body: StreamBuilder<List<Booking>>(
        stream: _bookings,
        builder: (context, snapshot) {
          final mine = (snapshot.data ?? const <Booking>[])
              .where((b) => b.clientId == user.id)
              .toList();
          final active = mine
              .where(
                (b) =>
                    b.status == BookingStatus.requested ||
                    b.status == BookingStatus.accepted,
              )
              .toList();
          final past = mine.where((b) => !active.contains(b)).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              _CondoCard(condo: condo),
              if (active.isNotEmpty) ...[
                const SectionHeader('Upcoming'),
                for (final booking in active) ...[
                  _ClientBookingCard(key: ValueKey(booking.id), booking: booking),
                  const SizedBox(height: 10),
                ],
              ],
              const SectionHeader('Book a clean'),
              FutureBuilder<List<CleaningPackage>>(
                future: _packages,
                builder: (context, packages) {
                  if (packages.hasError) {
                    return ErrorState(
                      message: 'We could not load cleaning packages.',
                      onRetry: _reloadPackages,
                    );
                  }
                  if (!packages.hasData) return const _PackagesLoading();
                  return Column(
                    children: [
                      for (final package in packages.data!) ...[
                        _PackageCard(package: package, condo: condo),
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                },
              ),
              const SectionHeader('Past bookings'),
              if (!snapshot.hasData)
                const Center(child: CircularProgressIndicator())
              else if (past.isEmpty)
                const EmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'No past bookings yet',
                  message:
                      'Completed and cancelled cleans will show up here.',
                )
              else
                for (final booking in past) ...[
                  _ClientBookingCard(key: ValueKey(booking.id), booking: booking),
                  const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _CondoCard extends StatelessWidget {
  const _CondoCard({required this.condo});

  final Condo condo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.apartment_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    condo.fullLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${condo.bedroomLabel}${condo.hasPets ? ' · Pets' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit condo',
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CondoFormScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.package, required this.condo});

  final CleaningPackage package;
  final Condo condo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BookPackageScreen(package: package),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      package.tagline,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'About ${formatHours(package.durationHours)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money(package.priceFor(condo.bedrooms)),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text('for your unit', style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackagesLoading extends StatelessWidget {
  const _PackagesLoading();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            height: 92,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
      ],
    );
  }
}

class _ClientBookingCard extends StatefulWidget {
  const _ClientBookingCard({super.key, required this.booking});

  final Booking booking;

  @override
  State<_ClientBookingCard> createState() => _ClientBookingCardState();
}

class _ClientBookingCardState extends State<_ClientBookingCard> {
  bool _cancelling = false;

  Future<void> _cancel() async {
    final session = context.read<Session>();
    final repository = context.read<BookingRepository>();
    setState(() => _cancelling = true);
    try {
      await repository.cancelBooking(
        bookingId: widget.booking.id,
        client: session.user!,
      );
      if (mounted) showMessage(context, 'Booking cancelled.');
    } on BookingException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.package.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StatusChip(status: booking.status),
              ],
            ),
            InfoRow(
              icon: Icons.event_outlined,
              text: formatSlot(booking.scheduledAt),
            ),
            InfoRow(
              icon: Icons.receipt_long_outlined,
              text: '${money(booking.price)} · ${booking.id}',
            ),
            const SizedBox(height: 12),
            switch (booking.status) {
              BookingStatus.requested => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(minHeight: 4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notifying available cleaners near ${booking.condo.buildingName}…',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _cancelling ? null : _cancel,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        _cancelling ? 'Cancelling…' : 'Cancel request',
                      ),
                    ),
                  ),
                ],
              ),
              BookingStatus.accepted => _CleanerRow(
                name: booking.cleanerName!,
                caption: 'Your cleaner is confirmed',
              ),
              BookingStatus.completed => _CleanerRow(
                name: booking.cleanerName!,
                caption: 'Cleaned your unit',
              ),
              BookingStatus.cancelled => Text(
                'You cancelled this request.',
                style: theme.textTheme.bodySmall,
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _CleanerRow extends StatelessWidget {
  const _CleanerRow({required this.name, required this.caption});

  final String name;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          InitialsAvatar(name: name),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(caption, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.verified_rounded, color: Color(0xFF0F766E)),
        ],
      ),
    );
  }
}
