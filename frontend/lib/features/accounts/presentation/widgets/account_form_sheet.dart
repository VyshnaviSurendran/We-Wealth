import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/inline_error_banner.dart';
import '../../application/accounts_providers.dart';
import '../../data/models/account_detail.dart';
import '../../data/models/account_type.dart';

/// Shows the create-account sheet.
Future<void> showCreateAccountSheet(BuildContext context, {required String householdId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => AccountFormSheet(householdId: householdId),
  );
}

/// Shows the edit-account sheet for an existing account.
///
/// Only `name` and `is_shared` are editable here, matching the backend's
/// `AccountUpdate` schema exactly — `account_type` and `opening_balance`
/// cannot be changed after creation.
Future<void> showEditAccountSheet(BuildContext context, {required AccountDetail account}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => AccountFormSheet(householdId: account.householdId, existingAccount: account),
  );
}

/// One sheet, two modes: creating a new account (all fields) or editing an
/// existing one (only `name`/`is_shared`, matching what the backend allows).
class AccountFormSheet extends ConsumerStatefulWidget {
  const AccountFormSheet({super.key, required this.householdId, this.existingAccount});

  final String householdId;
  final AccountDetail? existingAccount;

  bool get isEditing => existingAccount != null;

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _openingBalanceController;
  late AccountType _accountType;
  late bool _isShared;

  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAccount;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _openingBalanceController = TextEditingController(
      text: existing != null ? existing.openingBalance.toStringAsFixed(2) : '0.00',
    );
    _accountType = existing?.accountType ?? AccountType.bank;
    _isShared = existing?.isShared ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final controller = ref.read(accountsControllerProvider);
      if (widget.isEditing) {
        await controller.updateAccount(
          widget.householdId,
          widget.existingAccount!.id,
          name: _nameController.text.trim(),
          isShared: _isShared,
        );
      } else {
        await controller.createAccount(
          widget.householdId,
          name: _nameController.text.trim(),
          accountType: _accountType,
          openingBalance: double.parse(_openingBalanceController.text.trim()),
          isShared: _isShared,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _validateOpeningBalance(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Opening balance is required';
    if (double.tryParse(trimmed) == null) return 'Enter a valid amount';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isEditing ? 'Edit account' : 'New account',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                InlineErrorBanner(message: _errorMessage!),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              if (widget.isEditing) ...[
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Account type',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_accountType.displayName),
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Opening balance',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(Money.format(widget.existingAccount!.openingBalance)),
                ),
              ] else ...[
                DropdownButtonFormField<AccountType>(
                  initialValue: _accountType,
                  decoration: const InputDecoration(
                    labelText: 'Account type',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final type in AccountType.values)
                      DropdownMenuItem(value: type, child: Text(type.displayName)),
                  ],
                  onChanged: (value) => setState(() => _accountType = value ?? _accountType),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _openingBalanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Opening balance',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateOpeningBalance,
                ),
              ],
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Shared with partner'),
                subtitle: const Text('Visible to both household members'),
                value: _isShared,
                onChanged: (value) => setState(() => _isShared = value),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isEditing ? 'Save changes' : 'Create account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
