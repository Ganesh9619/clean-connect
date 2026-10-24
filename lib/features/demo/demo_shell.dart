import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/booking_repository.dart';
import '../../data/in_memory_booking_repository.dart';
import '../../data/sample_data.dart';
import '../../models/app_user.dart';
import '../../session/session.dart';
import '../../widgets/brand_mark.dart';
import 'device_app.dart';
import 'phone_frame.dart';

const _sideBySideMinWidth = 1000.0;

class _DemoDevice {
  const _DemoDevice({
    required this.label,
    required this.caption,
    required this.session,
  });

  final String label;
  final String caption;
  final Session session;
}

/// One client and two cleaners sharing a backend. Wide screens show three
/// phones side by side; narrow screens switch between them.
class DemoShell extends StatefulWidget {
  const DemoShell({super.key});

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  final _repository = InMemoryBookingRepository();
  late final List<_DemoDevice> _devices = [
    _DemoDevice(
      label: 'Client',
      caption: 'Signs up, adds a condo, books a package',
      session: Session(preferredRole: UserRole.client),
    ),
    _DemoDevice(
      label: 'Cleaner · Maria',
      caption: 'Available, gets notified of new jobs',
      session: Session(preferredRole: UserRole.cleaner, user: demoCleanerMaria),
    ),
    _DemoDevice(
      label: 'Cleaner · Ana',
      caption: 'Also available. First to accept wins',
      session: Session(preferredRole: UserRole.cleaner, user: demoCleanerAna),
    ),
  ];
  int _selected = 0;
  int _generation = 0;

  void _reset() {
    _repository.reset();
    for (final device in _devices) {
      device.session.reset();
    }
    setState(() => _generation++);
  }

  @override
  void dispose() {
    for (final device in _devices) {
      device.session.dispose();
    }
    _repository.dispose();
    super.dispose();
  }

  Widget _deviceApp(int index) => DeviceApp(
    key: ValueKey('device-$index-$_generation'),
    session: _devices[index].session,
  );

  @override
  Widget build(BuildContext context) {
    return Provider<BookingRepository>.value(
      value: _repository,
      child: LayoutBuilder(
        builder: (context, constraints) =>
            constraints.maxWidth >= _sideBySideMinWidth
            ? _buildSideBySide(context)
            : _buildSwitcher(context),
      ),
    );
  }

  Widget _buildSideBySide(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEFFAF7), Color(0xFFF6F7FB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 20, 32, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    const BrandMark(size: 40),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        'Live demo: a client books a condo clean, every available cleaner is notified, and the first to accept gets the job.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Reset demo'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < _devices.length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              children: [
                                Text(
                                  _devices[i].label,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  _devices[i].caption,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: PhoneFrame(child: _deviceApp(i)),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Built with Flutter (iOS, Android, web). Demo backend runs in memory; production uses Firebase Auth, Firestore, Cloud Functions and push notifications.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitcher(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 12,
        title: SegmentedButton<int>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            textStyle: const TextStyle(fontSize: 13),
          ),
          segments: const [
            ButtonSegment(value: 0, label: Text('Client')),
            ButtonSegment(value: 1, label: Text('Maria')),
            ButtonSegment(value: 2, label: Text('Ana')),
          ],
          selected: {_selected},
          onSelectionChanged: (value) =>
              setState(() => _selected = value.first),
        ),
        actions: [
          IconButton(
            tooltip: 'Reset demo',
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: brandColor.withValues(alpha: 0.15)),
        ),
      ),
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: IndexedStack(
          index: _selected,
          children: [
            for (var i = 0; i < _devices.length; i++) _deviceApp(i),
          ],
        ),
      ),
    );
  }
}
