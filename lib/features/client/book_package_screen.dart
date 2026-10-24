import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/format.dart';
import '../../data/booking_repository.dart';
import '../../models/cleaning_package.dart';
import '../../session/session.dart';
import '../../widgets/common.dart';

const _slotHours = [8, 10, 12, 14, 16];

class BookPackageScreen extends StatefulWidget {
  const BookPackageScreen({super.key, required this.package});

  final CleaningPackage package;

  @override
  State<BookPackageScreen> createState() => _BookPackageScreenState();
}

class _BookPackageScreenState extends State<BookPackageScreen> {
  final _notes = TextEditingController();
  late final List<DateTime> _days = _nextDays();
  late DateTime _day = _days.first;
  int? _hour;
  bool _submitting = false;

  static List<DateTime> _nextDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = [for (var i = 0; i < 7; i++) today.add(Duration(days: i))];
    final todayHasSlots = _slotHours.any(
      (h) => today.add(Duration(hours: h)).isAfter(now.add(const Duration(hours: 2))),
    );
    return todayHasSlots ? days : days.skip(1).toList();
  }

  bool _slotAvailable(int hour) => _day
      .add(Duration(hours: hour))
      .isAfter(DateTime.now().add(const Duration(hours: 2)));

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final hour = _hour;
    if (hour == null) {
      showMessage(context, 'Pick a start time.', error: true);
      return;
    }
    final session = context.read<Session>();
    final repository = context.read<BookingRepository>();
    setState(() => _submitting = true);
    try {
      await repository.createBooking(
        client: session.user!,
        condo: session.condo!,
        package: widget.package,
        scheduledAt: _day.add(Duration(hours: hour)),
        notes: _notes.text,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Booking sent. Available cleaners are being notified.'),
        ),
      );
    } on BookingException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showMessage(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final condo = context.watch<Session>().condo!;
    final package = widget.package;
    final price = package.priceFor(condo.bedrooms);
    final extraBedrooms = condo.bedrooms - CleaningPackage.includedBedrooms;

    return Scaffold(
      appBar: AppBar(title: Text(package.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(
            package.tagline,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "What's included",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  for (final item in package.includes)
                    InfoRow(icon: Icons.check_circle_outline, text: item),
                ],
              ),
            ),
          ),
          const SectionHeader('Date'),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final day = _days[index];
                final selected = day == _day;
                return _DayTile(
                  day: day,
                  selected: selected,
                  onTap: () => setState(() {
                    _day = day;
                    if (_hour != null && !_slotAvailable(_hour!)) _hour = null;
                  }),
                );
              },
            ),
          ),
          const SectionHeader('Start time'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final hour in _slotHours)
                ChoiceChip(
                  label: Text(
                    DateFormat('h:mm a').format(DateTime(2000, 1, 1, hour)),
                  ),
                  selected: _hour == hour,
                  showCheckmark: false,
                  onSelected: _slotAvailable(hour)
                      ? (_) => setState(() => _hour = hour)
                      : null,
                ),
            ],
          ),
          const SectionHeader('Notes for your cleaner'),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Focus areas, supplies, anything to avoid…',
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _PriceLine(
                    label: '${package.name} (up to 2 bedrooms)',
                    value: money(package.basePrice),
                  ),
                  if (extraBedrooms > 0)
                    _PriceLine(
                      label:
                          '$extraBedrooms extra bedroom${extraBedrooms > 1 ? 's' : ''}',
                      value: money(extraBedrooms * package.pricePerExtraBedroom),
                    ),
                  const Divider(height: 20),
                  _PriceLine(label: 'Total', value: money(price), bold: true),
                  const SizedBox(height: 4),
                  Text(
                    'Pay your cleaner after the visit. No charge until a cleaner accepts.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Text('Request booking · ${money(price)}'),
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;
    return Material(
      color: selected ? scheme.primary : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('EEE').format(day),
                style: TextStyle(color: foreground, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                '${day.day}',
                style: TextStyle(
                  color: foreground,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
      fontSize: bold ? 16 : null,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
