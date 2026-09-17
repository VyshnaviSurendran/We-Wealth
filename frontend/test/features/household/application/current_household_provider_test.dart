import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_balance/features/household/application/current_household_provider.dart';
import 'package:our_balance/features/household/data/household_api.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('currentHouseholdProvider', () {
    test('resolves to the first household when the user has any', () async {
      final container = ProviderContainer(
        overrides: [
          householdApiProvider.overrideWithValue(
            FakeHouseholdApi(households: [testHousehold]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final household = await container.read(currentHouseholdProvider.future);

      expect(household?.id, testHousehold.id);
    });

    test('resolves to null when the user has no household yet', () async {
      final container = ProviderContainer(
        overrides: [
          householdApiProvider.overrideWithValue(FakeHouseholdApi(households: [])),
        ],
      );
      addTearDown(container.dispose);

      final household = await container.read(currentHouseholdProvider.future);

      expect(household, isNull);
    });
  });
}
