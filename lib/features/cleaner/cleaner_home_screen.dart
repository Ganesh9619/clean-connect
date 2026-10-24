import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/format.dart';
import '../../data/booking_repository.dart';
import '../../models/booking.dart';
import '../../session/session.dart';
import '../../widgets/common.dart';
import 'job_card.dart';

/// How long a job taken by another cleaner stays visible, so the cleaner
/// understands why it disappeared.
const _takenJobVisibleFor = Duration(seconds: 45);

class CleanerHomeScreen extends StatefulWidget {
  const CleanerHomeScreen({super.key});

  @override
  State<CleanerHomeScreen> createState() => _CleanerHomeScreenState();
}

class _CleanerHomeScreenState extends State<CleanerHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  late final Stream<List<Booking>> _bookings = context
      .read<BookingRepository>()
      .watchBookings();
  late final Timer _expireTakenJobs;

  @override
  void initState() {
    super.initState();
    _expireTakenJobs = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _expireTakenJobs.cancel();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final me = session.user!;
    return StreamBuilder<List<Booking>>(
      stream: _bookings,
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <Booking>[];
        final now = DateTime.now();
        final open = all.where((b) {
          if (b.isOpen) return true;
          final takenByOther =
              b.status == BookingStatus.accepted &&
              b.cleanerId != me.id &&
              now.difference(b.acceptedAt!) < _takenJobVisibleFor;
          return takenByOther;
        }).toList();
        final mine =
            all
                .where(
                  (b) =>
                      b.cleanerId == me.id &&
                      b.status != BookingStatus.cancelled,
                )
                .toList()
              ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        final openCount = open.where((b) => b.isOpen).length;
        return Scaffold(
          appBar: AppBar(
            title: Text('Hi, ${me.firstName}'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: InitialsAvatar(name: me.name, radius: 16),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(116),
              child: Column(
                children: [
                  _AvailabilityCard(
                    available: session.available,
                    onChanged: session.setAvailable,
                  ),
                  TabBar(
                    controller: _tabs,
                    tabs: [
                      Tab(text: 'Open jobs ($openCount)'),
                      Tab(text: 'My jobs (${mine.length})'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _OpenJobs(
                      jobs: open,
                      available: session.available,
                      onAccepted: () => _tabs.animateTo(1),
                    ),
                    _MyJobs(jobs: mine),
                  ],
                ),
        );
      },
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.available, required this.onChanged});

  final bool available;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        decoration: BoxDecoration(
          color: available
              ? const Color(0xFFE6F6F3)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              available ? Icons.circle : Icons.circle_outlined,
              size: 12,
              color: available ? const Color(0xFF16A34A) : Colors.grey,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                available
                    ? 'Available · receiving new jobs'
                    : 'Offline · not receiving jobs',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch.adaptive(value: available, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _OpenJobs extends StatelessWidget {
  const _OpenJobs({
    required this.jobs,
    required this.available,
    required this.onAccepted,
  });

  final List<Booking> jobs;
  final bool available;
  final VoidCallback onAccepted;

  @override
  Widget build(BuildContext context) {
    if (!available) {
      return Builder(
        builder: (context) => ListView(
          children: [
            EmptyState(
              icon: Icons.notifications_paused_outlined,
              title: "You're offline",
              message:
                  'Turn on availability to see open jobs and get notified when a client books.',
              action: FilledButton(
                onPressed: () => context.read<Session>().setAvailable(true),
                child: const Text('Go available'),
              ),
            ),
          ],
        ),
      );
    }
    if (jobs.isEmpty) {
      return ListView(
        children: const [
          EmptyState(
            icon: Icons.notifications_active_outlined,
            title: 'No open jobs right now',
            message:
                "You'll get a notification the moment a client nearby books a clean.",
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => OpenJobCard(
        key: ValueKey(jobs[index].id),
        booking: jobs[index],
        onAccepted: onAccepted,
      ),
    );
  }
}

class _MyJobs extends StatelessWidget {
  const _MyJobs({required this.jobs});

  final List<Booking> jobs;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return ListView(
        children: const [
          EmptyState(
            icon: Icons.work_outline_rounded,
            title: 'No jobs yet',
            message:
                'Jobs you accept show up here with the full address and access notes.',
          ),
        ],
      );
    }
    final earned = jobs
        .where((b) => b.status == BookingStatus.completed)
        .fold<int>(0, (sum, b) => sum + b.cleanerPayout);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Earned from completed jobs',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  money(earned),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final job in jobs) ...[
          MyJobCard(key: ValueKey(job.id), booking: job),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
