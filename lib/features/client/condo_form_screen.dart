import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/sample_data.dart';
import '../../models/condo.dart';
import '../../session/session.dart';

class CondoFormScreen extends StatefulWidget {
  const CondoFormScreen({super.key, this.isOnboarding = false});

  final bool isOnboarding;

  @override
  State<CondoFormScreen> createState() => _CondoFormScreenState();
}

class _CondoFormScreenState extends State<CondoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Condo? _existing = context.read<Session>().condo;
  late final _building = TextEditingController(text: _existing?.buildingName);
  late final _address = TextEditingController(text: _existing?.address);
  late final _tower = TextEditingController(text: _existing?.tower);
  late final _unit = TextEditingController(text: _existing?.unit);
  late final _access = TextEditingController(text: _existing?.accessNotes);
  late int _bedrooms = _existing?.bedrooms ?? 1;
  late int _bathrooms = _existing?.bathrooms ?? 1;
  late bool _hasPets = _existing?.hasPets ?? false;

  @override
  void dispose() {
    _building.dispose();
    _address.dispose();
    _tower.dispose();
    _unit.dispose();
    _access.dispose();
    super.dispose();
  }

  void _fillSample() {
    _building.text = sampleCondo.buildingName;
    _address.text = sampleCondo.address;
    _tower.text = sampleCondo.tower;
    _unit.text = sampleCondo.unit;
    _access.text = sampleCondo.accessNotes;
    setState(() {
      _bedrooms = sampleCondo.bedrooms;
      _bathrooms = sampleCondo.bathrooms;
      _hasPets = sampleCondo.hasPets;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<Session>().saveCondo(
      Condo(
        buildingName: _building.text.trim(),
        address: _address.text.trim(),
        tower: _tower.text.trim(),
        unit: _unit.text.trim(),
        bedrooms: _bedrooms,
        bathrooms: _bathrooms,
        accessNotes: _access.text.trim(),
        hasPets: _hasPets,
      ),
    );
    if (!widget.isOnboarding) Navigator.of(context).pop();
  }

  String? _required(String? value, String label) =>
      (value == null || value.trim().isEmpty) ? 'Enter $label' : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isOnboarding ? 'Your condo' : 'Edit condo'),
        actions: [
          TextButton(onPressed: _fillSample, child: const Text('Sample')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            if (widget.isOnboarding)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Cleaners see the building and size when a job is offered. Tower, unit and access notes are shared only with the cleaner who accepts.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            TextFormField(
              controller: _building,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Building name'),
              validator: (v) => _required(v, 'the building name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Street address'),
              validator: (v) => _required(v, 'the address'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tower,
                    decoration: const InputDecoration(
                      labelText: 'Tower / block',
                      hintText: 'Optional',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unit,
                    decoration: const InputDecoration(labelText: 'Unit no.'),
                    validator: (v) => _required(v, 'the unit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Bedrooms', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _CountPicker(
              values: const [0, 1, 2, 3, 4, 5],
              labelFor: (v) => v == 0 ? 'Studio' : '$v',
              selected: _bedrooms,
              onChanged: (v) => setState(() => _bedrooms = v),
            ),
            const SizedBox(height: 16),
            Text('Bathrooms', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _CountPicker(
              values: const [1, 2, 3, 4],
              labelFor: (v) => '$v',
              selected: _bathrooms,
              onChanged: (v) => setState(() => _bathrooms = v),
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pets at home'),
              subtitle: const Text('So cleaners can come prepared'),
              value: _hasPets,
              onChanged: (v) => setState(() => _hasPets = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _access,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Access notes',
                hintText: 'Concierge, key pickup, parking, gate code…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: Text(widget.isOnboarding ? 'Save and continue' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountPicker extends StatelessWidget {
  const _CountPicker({
    required this.values,
    required this.labelFor,
    required this.selected,
    required this.onChanged,
  });

  final List<int> values;
  final String Function(int) labelFor;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          ChoiceChip(
            label: Text(labelFor(value)),
            selected: value == selected,
            showCheckmark: false,
            onSelected: (_) => onChanged(value),
          ),
      ],
    );
  }
}
