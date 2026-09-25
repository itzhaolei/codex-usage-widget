import '../../core/models.dart';

class QuotaRechargeTransition {
  const QuotaRechargeTransition({
    required this.fromPercentage,
    required this.toPercentage,
  });

  final int fromPercentage;
  final int toPercentage;
}

class QuotaRechargeEvent extends QuotaRechargeTransition {
  const QuotaRechargeEvent({
    required this.id,
    required super.fromPercentage,
    required super.toPercentage,
  });

  final int id;
}

/// Only a weekly reset for the same account starts a recharge animation.
QuotaRechargeTransition? quotaRechargeTransition(
  QuotaSnapshot? previous,
  QuotaSnapshot? next,
) {
  if (previous == null ||
      next == null ||
      previous.accountFingerprint == null ||
      previous.accountFingerprint != next.accountFingerprint) {
    return null;
  }
  final previousWindow = previous.weeklyWindow;
  final nextWindow = next.weeklyWindow;
  final previousReset = previousWindow?.resetsAt;
  final nextReset = nextWindow?.resetsAt;
  final from = previousWindow?.remainingPercentage;
  final to = nextWindow?.remainingPercentage;
  if (previousReset == null ||
      nextReset == null ||
      !nextReset.isAfter(previousReset.add(const Duration(minutes: 5))) ||
      from == null ||
      to == null ||
      to <= from) {
    return null;
  }
  return QuotaRechargeTransition(fromPercentage: from, toPercentage: to);
}
