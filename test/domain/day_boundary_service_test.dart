import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/services/day_boundary_service.dart';

void main() {
  late DayBoundaryService svc;

  setUp(() => svc = DayBoundaryService());

  test('05:59 returns previous day', () {
    final dt = DateTime(2026, 5, 15, 5, 59);
    expect(svc.effectiveDate(dt), DateTime(2026, 5, 14));
  });

  test('06:00 returns current day', () {
    final dt = DateTime(2026, 5, 15, 6, 0);
    expect(svc.effectiveDate(dt), DateTime(2026, 5, 15));
  });

  test('06:01 returns current day', () {
    final dt = DateTime(2026, 5, 15, 6, 1);
    expect(svc.effectiveDate(dt), DateTime(2026, 5, 15));
  });

  test('00:00 midnight returns previous day', () {
    final dt = DateTime(2026, 5, 15, 0, 0);
    expect(svc.effectiveDate(dt), DateTime(2026, 5, 14));
  });

  test('23:59 returns current day', () {
    final dt = DateTime(2026, 5, 15, 23, 59);
    expect(svc.effectiveDate(dt), DateTime(2026, 5, 15));
  });

  test('formatDate produces YYYY-MM-DD', () {
    expect(svc.formatDate(DateTime(2026, 1, 5)), '2026-01-05');
    expect(svc.formatDate(DateTime(2026, 12, 31)), '2026-12-31');
  });

  test('formatDate and parseDate round-trip', () {
    final original = DateTime(2026, 5, 15);
    final formatted = svc.formatDate(original);
    expect(svc.parseDate(formatted), original);
  });

  test('cross-month boundary: May 1st 05:59 → April 30th', () {
    final dt = DateTime(2026, 5, 1, 5, 0);
    expect(svc.effectiveDate(dt), DateTime(2026, 4, 30));
  });
}
