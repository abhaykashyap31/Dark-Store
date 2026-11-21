import 'package:flutter/material.dart';

import '../../../../shared/models/address.dart';

/// Centered Add / Edit address dialog. Returns a draft [Address] on save.
Future<Address?> showAddressEditorDialog(
  BuildContext context, {
  Address? initial,
}) {
  return showDialog<Address>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    useRootNavigator: true,
    builder: (dialogContext) => _AddressEditorDialog(initial: initial),
  );
}

class _AddressEditorDialog extends StatefulWidget {
  const _AddressEditorDialog({this.initial});

  final Address? initial;

  @override
  State<_AddressEditorDialog> createState() => _AddressEditorDialogState();
}

class _AddressEditorDialogState extends State<_AddressEditorDialog> {
  late final TextEditingController _label;
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _postal;
  late bool _makeDefault;
  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _label = TextEditingController(text: initial?.label ?? 'Home');
    _line1 = TextEditingController(text: initial?.line1 ?? '');
    _line2 = TextEditingController(text: initial?.line2 ?? '');
    _city = TextEditingController(text: initial?.city ?? 'Bengaluru');
    _state = TextEditingController(text: initial?.state ?? 'KA');
    _postal = TextEditingController(text: initial?.postalCode ?? '');
    _makeDefault = initial?.defaultAddress ?? !_isEdit;
  }

  @override
  void dispose() {
    _label.dispose();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _state.dispose();
    _postal.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      Address(
        id: widget.initial?.id ?? 'temp',
        label: _label.text.trim().isEmpty ? 'Home' : _label.text.trim(),
        line1: _line1.text.trim(),
        line2: _line2.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim(),
        postalCode: _postal.text.trim(),
        defaultAddress: _makeDefault,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Material(
            color: Colors.white,
            elevation: 12,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomInset),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _isEdit ? 'Edit address' : 'Add address',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _label,
                        decoration: const InputDecoration(labelText: 'Label'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _line1,
                        decoration: const InputDecoration(
                          labelText: 'Address line 1',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _line2,
                        decoration: const InputDecoration(
                          labelText: 'Address line 2',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _city,
                        decoration: const InputDecoration(labelText: 'City'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _state,
                        decoration: const InputDecoration(labelText: 'State'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _postal,
                        decoration: const InputDecoration(
                          labelText: 'Postal code',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _makeDefault,
                        onChanged: (value) =>
                            setState(() => _makeDefault = value ?? false),
                        title: const Text('Set as default address'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _submit,
                        child: Text(_isEdit ? 'Save changes' : 'Save address'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
