import '../enums/pao_tone.dart';

int defaultPaoMonths(String categoryId) => switch (categoryId) {
      'cat-toner' => 18,
      'cat-cleanser' ||
      'cat-retinoid' ||
      'cat-serum' ||
      'cat-moisturizer' ||
      'cat-oil' ||
      'cat-spf' =>
        12,
      _ => 12,
    };

class PaoProgress {
  final double fraction;
  final int monthsRemaining;
  final PaoTone tone;
  final bool isOpened;

  const PaoProgress({
    required this.fraction,
    required this.monthsRemaining,
    required this.tone,
    required this.isOpened,
  });
}

class PaoCalculator {
  const PaoCalculator();

  PaoProgress compute({
    DateTime? openedDate,
    required int paoMonths,
    required DateTime now,
  }) {
    if (openedDate == null) {
      return PaoProgress(
        fraction: 0,
        monthsRemaining: paoMonths,
        tone: PaoTone.ok,
        isOpened: false,
      );
    }
    final elapsedMonths = now.difference(openedDate).inDays / 30.44;
    final fraction = paoMonths <= 0 ? 1.0 : elapsedMonths / paoMonths;
    final remaining = (paoMonths - elapsedMonths).round();
    final tone = fraction >= 1.0
        ? PaoTone.bad
        : (fraction >= 0.8 ? PaoTone.warn : PaoTone.ok);
    return PaoProgress(
      fraction: fraction,
      monthsRemaining: remaining < 0 ? 0 : remaining,
      tone: tone,
      isOpened: true,
    );
  }
}
