import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/registration.dart';
import '../../../state/registration_providers.dart';
import 'registration_list_page.dart';
import 'registration_validators.dart';

class RegistrationPage extends ConsumerStatefulWidget {
  const RegistrationPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends ConsumerState<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaC = TextEditingController();
  final _nimC = TextEditingController();
  final _emailC = TextEditingController();

  static const _daftarProdi = [
    'Teknologi Informasi',
    'Teknik Industri',
  ];

  String? _prodi;
  bool _setuju = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _namaC.dispose();
    _nimC.dispose();
    _emailC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (!_setuju) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Centang persetujuan terlebih dahulu')),
      );
      return;
    }

    final reg = Registration(
      agendaId: widget.id,
      nama: _namaC.text.trim(),
      nim: _nimC.text.trim(),
      email: _emailC.text.trim(),
      prodi: _prodi!,
      createdAt: DateTime.now(),
    );

    setState(() => _isSubmitting = true);

    try {
      await ref.read(registrationRepositoryProvider).add(reg);
      ref.invalidate(registrationsProvider(widget.id)); // minta daftar dimuat ulang

      if (!mounted) return;

      _formKey.currentState!.reset();
      _namaC.clear();
      _nimC.clear();
      _emailC.clear();

      setState(() {
        _prodi = null;
        _setuju = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registrasi ${reg.nama} berhasil')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const jarak = SizedBox(height: 16);

    return Scaffold(
      appBar: AppBar(
        title: Text('Registrasi ${widget.id}'),
        actions: [
          IconButton(
            tooltip: 'Daftar peserta',
            icon: const Icon(Icons.people),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RegistrationListPage(id: widget.id),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _namaC,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama lengkap',
                border: OutlineInputBorder(),
              ),
              validator: RegistrationValidators.nama,
            ),
            jarak,
            TextFormField(
              controller: _nimC,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 12,
              decoration: const InputDecoration(
                labelText: 'NIM',
                border: OutlineInputBorder(),
              ),
              validator: RegistrationValidators.nim,
            ),
            jarak,
            TextFormField(
              controller: _emailC,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'nama@kampus.ac.id',
                border: OutlineInputBorder(),
              ),
              validator: RegistrationValidators.email,
            ),
            jarak,
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Program studi',
                border: OutlineInputBorder(),
              ),
              items: _daftarProdi
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _prodi = v),
              validator: RegistrationValidators.prodi,
            ),
            jarak,
            CheckboxListTile(
              value: _setuju,
              onChanged: (v) => setState(() => _setuju = v ?? false),
              title: const Text('Data yang saya isi sudah benar'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            jarak,
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Daftar'),
            ),
          ],
        ),
      ),
    );
  }
}