import 'package:flutter_test/flutter_test.dart';
import 'package:datafightcentral/models/contract_tier.dart';
import 'package:datafightcentral/models/promotion.dart';

void main() {
  test('ContractTier maps correctly', () {
    final tier = ContractTier.fromMap({
      'id': 'starter',
      'name': 'Starter',
      'criteria': {'viral_flag': false},
      'rate_key': 'RATE_STARTER',
    });

    expect(tier.id, 'starter');
    expect(tier.rateKey, 'RATE_STARTER');
    expect(tier.toMap()['criteria'], {'viral_flag': false});
  });

  test('Promotion maps correctly', () {
    final promotion = Promotion.fromMap({
      'id': 'promo-ppv',
      'title': 'Event PPV',
      'description': 'Full event access',
      'enabled': true,
      'ui': {'label': 'Buy Event'},
    });

    expect(promotion.id, 'promo-ppv');
    expect(promotion.enabled, true);
    expect(promotion.toMap()['ui'], {'label': 'Buy Event'});
  });
}
