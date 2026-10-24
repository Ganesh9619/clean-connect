import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/format.dart';
import '../../data/booking_repository.dart';
import '../../models/booking.dart';
import '../../session/session.dart';
import '../../widgets/common.dart';

class OpenJobCard extends StatefulWidget {
  const OpenJobCard({
    super.key,
    required this.booking,
    required this.onAccepted,
  });

  final Booking booking;
  final VoidCallback onAccepted;

  @override
  State<OpenJobCard> createState() => _OpenJobCardState();
}

class _OpenJobCardState extends State<OpenJobCard> {
  bool _accepting = false;

  Future<void> _accept() async {
    final cleaner = context.read<Session>().user!;
    setState(() => _accepting = true);
    final result = await context.read<BookingRepository>().acceptBooking(
      bookingId: widget.booking.id,
      cleaner: cleaner,
    );
    if (!mounted) return;
    setState(() => _accepting = false);
    switch (result.outcome) {
      case AcceptOutcome.accepted:
        showMessage(context, 'Job accepted. Full address is in My jobs.');
        widget.onAccepted();
      case AcceptOutcome.alreadyTaken:
        final winner = result.booking?.cleanerName?.split(' ').first;
        showMessage(
          context,
          '${winner ?? 'Another cleaner'} accepted this job first.',
          error: true,
        );
      case AcceptOutcome.unavailable:
        showMessage(context, 'The client cancelled this booking.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final theme = Theme.of(context);
    final taken = !booking.isOpen;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: taken ? 0.55 : 1,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.package.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          booking.condo.publicLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        money(booking.cleanerPayout),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text('your payout', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              InfoRow(
                icon: Icons.event_outlined,
                text: formatSlot(booking.scheduledAt),
              ),
              InfoRow(
                icon: Icons.schedule_rounded,
                text: 'About ${formatHours(booking.package.durationHours)}',
              ),
              InfoRow(
                icon: Icons.place_outlined,
                text: booking.condo.address,
              ),
              if (booking.condo.hasPets)
                const InfoRow(icon: Icons.pets_outlined, text: 'Pets at home'),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: taken
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.lock_outline, size: 18),
                        label: Text(
                          'Taken by ${booking.cleanerName?.split(' ').first ?? 'another cleaner'}',
                        ),
                      )
                    : FilledButton(
                        onPressed: _accepting ? null : _accept,
                        child: _accepting
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text('Accept job'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyJobCard extends StatefulWidget {
  const MyJobCard({super.key, required this.booking});

  final Booking booking;

  @override
  State<MyJobCard> createState() => _MyJobCardState();
}

class _MyJobCardState extends State<MyJobCard> {
  bool _completing = false;

  Future<void> _complete() async {
    final cleaner = context.read<Session>().user!;
    setState(() => _completing = true);
    try {
      await context.read<BookingRepository>().completeBooking(
        bookingId: widget.booking.id,
        cleaner: cleaner,
      );
      if (mounted) {
        showMessage(
          context,
          'Marked as completed. ${money(widget.booking.cleanerPayout)} added to your earnings.',
        );
      }
    } on BookingException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final theme = Theme.of(context);
    final done = booking.status == BookingStatus.completed;
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
            InfoRow(icon: Icons.apartment_rounded, text: booking.condo.fullLabel),
            InfoRow(icon: Icons.place_outlined, text: booking.condo.address),
            InfoRow(
              icon: Icons.bed_outlined,
              text:
                  '${booking.condo.bedroomLabel}${booking.condo.hasPets ? ' · Pets at home' : ''}',
            ),
            if (booking.condo.accessNotes.isNotEmpty)
              InfoRow(
                icon: Icons.key_outlined,
                text: booking.condo.accessNotes,
              ),
            if (booking.notes.isNotEmpty)
              InfoRow(
                icon: Icons.sticky_note_2_outlined,
                text: '"${booking.notes}"',
              ),
            const Divider(height: 24),
            Row(
              children: [
                InitialsAvatar(name: booking.clientName),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.clientName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(booking.clientPhone, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Text(
                  money(booking.cleanerPayout),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (!done) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _completing ? null : _complete,
                  icon: const Icon(Icons.task_alt_rounded),
                  label: Text(_completing ? 'Saving…' : 'Mark completed'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
