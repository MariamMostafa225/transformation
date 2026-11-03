import 'package:flutter/material.dart';

import '../../../data/models/car.dart';
import '../../../data/models/company.dart';

class CarFormResult {
  const CarFormResult({
    required this.carNumber,
    required this.letters,
    required this.companyId,
  });

  final String carNumber;
  final String letters;
  final String companyId;
}

Future<CarFormResult?> showCarFormDialog({
  required BuildContext context,
  required List<Company> companies,
  Car? car,
}) {
  return showDialog<CarFormResult>(
    context: context,
    builder: (_) => _CarFormDialog(companies: companies, car: car),
  );
}

class _CarFormDialog extends StatefulWidget {
  const _CarFormDialog({required this.companies, this.car});

  final List<Company> companies;
  final Car? car;

  @override
  State<_CarFormDialog> createState() => _CarFormDialogState();
}

class _CarFormDialogState extends State<_CarFormDialog> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _number;
  late final TextEditingController _letters;
  late String? _companyId;

  @override
  void initState() {
    super.initState();
    _number = TextEditingController(text: widget.car?.carNumber ?? '');
    _letters = TextEditingController(text: widget.car?.letters ?? '');
    _companyId =
        widget.car?.companyId ??
        (widget.companies.isEmpty ? null : widget.companies.first.id);
  }

  @override
  void dispose() {
    _number.dispose();
    _letters.dispose();
    super.dispose();
  }

  void _save() {
    if (!_key.currentState!.validate() || _companyId == null) return;
    Navigator.of(context).pop(
      CarFormResult(
        carNumber: _number.text.trim(),
        letters: _letters.text.trim().replaceAll(RegExp(r'\s+'), ' '),
        companyId: _companyId!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.car == null ? 'إضافة سيارة' : 'تعديل سيارة'),
      content: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _number,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'رقم السيارة',
                  hintText: 'مثال: 0123',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'أدخل رقم السيارة.';
                  }
                  return RegExp(r'^[0-9٠-٩]+$').hasMatch(value.trim())
                      ? null
                      : 'استخدم الأرقام فقط.';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _letters,
                decoration: const InputDecoration(
                  labelText: 'الحروف الثلاثة',
                  hintText: 'مثال: م ى د',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (!RegExp(r'^[\u0621-\u064A\s]+$').hasMatch(text)) {
                    return 'أدخل الحروف العربية فقط.';
                  }
                  final letters = RegExp(r'[\u0621-\u064A]')
                      .allMatches(text)
                      .length;
                  return letters == 3 ? null : 'أدخل ثلاثة أحرف عربية بالضبط.';
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _companyId,
                decoration: const InputDecoration(labelText: 'الشركة'),
                items: widget.companies
                    .map(
                      (company) => DropdownMenuItem(
                        value: company.id,
                        child: Text(
                          company.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => _companyId = value),
                validator: (value) => value == null ? 'اختر الشركة.' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _save, child: const Text('حفظ')),
      ],
    );
  }
}
