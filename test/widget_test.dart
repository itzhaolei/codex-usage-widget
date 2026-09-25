import 'package:flutter_test/flutter_test.dart';

import 'package:quota_bubble/core/models.dart';
import 'package:quota_bubble/data/usage_api.dart';

void main() {
  test('normalizes plan badges including business tiers', () {
    expect(planBadgeText('Business Premium 5x'), 'Business 5x');
    expect(planBadgeText('Business Premium 20x'), 'Business 20x');
    expect(planBadgeText('Pro5x'), 'Pro 5x');
    expect(normalizePlanType('plus'), 'plus');
  });

  test('parses epoch timestamps in seconds and milliseconds', () {
    expect(
      parseTimestamp(1_700_000_000)!.millisecondsSinceEpoch,
      1_700_000_000_000,
    );
    expect(
      parseTimestamp(1_700_000_000_000)!.millisecondsSinceEpoch,
      1_700_000_000_000,
    );
  });

  test('parses usage payload windows and balance', () {
    final payload = UsageApi.parseUsage('''{
      "rate_limit": {
        "primary_window": {"used_percent": 35, "reset_at": 1700000000},
        "secondary_window": {"used_percent": 12, "reset_at": 1700600000}
      },
      "credits": {"balance": "4.5"},
      "plan": {"type": "business_5x"}
    }''');
    expect(payload, isNotNull);
    expect(payload!.fiveHour!.usedPercentage, 35);
    expect(payload.sevenDay!.usedPercentage, 12);
    expect(payload.balanceUsd, '4.5');
  });
}
