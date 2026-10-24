import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/sample_data.dart';
import '../../models/app_user.dart';
import '../../session/session.dart';
import '../../widgets/common.dart';
import '../../widgets/brand_mark.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  late UserRole _role = context.read<Session>().preferredRole;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _fillSample() {
    _name.text = sampleClientName;
    _email.text = sampleClientEmail;
    _phone.text = sampleClientPhone;
    setState(() => _role = UserRole.client);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await context.read<Session>().signUp(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        role: _role,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showMessage(context, 'Could not create your account. Try again.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            children: [
              const BrandMark(size: 52),
              const SizedBox(height: 24),
              Text(
                'Spotless condos,\nbooked in a minute.',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create an account to book vetted cleaners for your unit, or to start picking up cleaning jobs nearby.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              SegmentedButton<UserRole>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: UserRole.client,
                    icon: Icon(Icons.home_outlined),
                    label: Text('I need a clean'),
                  ),
                  ButtonSegment(
                    value: UserRole.cleaner,
                    icon: Icon(Icons.cleaning_services_outlined),
                    label: Text("I'm a cleaner"),
                  ),
                ],
                selected: {_role},
                onSelectionChanged: (value) =>
                    setState(() => _role = value.first),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Enter your name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  return valid.hasMatch(value) ? null : 'Enter a valid email';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  helperText: 'Shared with your cleaner only after they accept',
                ),
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  return digits.length < 7 ? 'Enter a valid phone number' : null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Create account'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _submitting ? null : _fillSample,
                child: const Text('Use sample details'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
