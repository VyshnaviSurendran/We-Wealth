import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/household_api.dart';
import '../data/models/household.dart';

/// Resolves which household the dashboard/accounts screens operate on.
///
/// There is no household-selection UI yet (out of scope for this task) and
/// no server-side "default household" concept, so this simply uses the
/// first household returned by `GET /households` for the signed-in user.
/// `null` means the user has no household yet — screens depending on this
/// should show an explanatory empty state rather than erroring.
final currentHouseholdProvider = FutureProvider<Household?>((ref) async {
  final households = await ref.watch(householdApiProvider).listHouseholds();
  return households.isEmpty ? null : households.first;
});
