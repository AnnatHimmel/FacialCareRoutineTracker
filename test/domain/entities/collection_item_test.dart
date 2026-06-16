import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/collection_item.dart';
import 'package:skincare_tracker/domain/enums/collection_status.dart';

void main() {
  group('CollectionItem', () {
    final baseTime = DateTime(2026, 6, 15, 10, 30);
    final futureTime = DateTime(2026, 6, 20, 14, 45);

    group('copyWith', () {
      test('should_change_status_from_inUse_to_sealed_with_copyWith', () {
        /**
         * Given: A CollectionItem with status = inUse
         * When: copyWith(status: sealed) is called
         * Then: returned instance has status = sealed
         */
        final item = CollectionItem(
          id: 'item-1',
          productId: 'prod-1',
          status: CollectionStatus.inUse,
          openedDate: null,
          paoMonths: 12,
          notificationsEnabled: true,
          lastModified: baseTime,
        );

        final updated = item.copyWith(status: CollectionStatus.sealed);

        expect(updated.status, CollectionStatus.sealed);
      });

      test('should_set_openedDate_to_null_when_explicitly_passed_null', () {
        /**
         * Given: A CollectionItem with openedDate = some datetime
         * When: copyWith(openedDate: null) is called with sentinel support
         * Then: returned instance has openedDate = null
         */
        final item = CollectionItem(
          id: 'item-2',
          productId: 'prod-2',
          status: CollectionStatus.inUse,
          openedDate: baseTime,
          paoMonths: 12,
          notificationsEnabled: true,
          lastModified: baseTime,
        );

        final updated = item.copyWith(openedDate: null);

        expect(updated.openedDate, isNull);
      });

      test('should_preserve_openedDate_when_not_specified_in_copyWith', () {
        /**
         * Given: A CollectionItem with openedDate = some datetime
         * When: copyWith(status: sealed) is called (openedDate not specified)
         * Then: returned instance still has the same openedDate
         */
        final item = CollectionItem(
          id: 'item-3',
          productId: 'prod-3',
          status: CollectionStatus.inUse,
          openedDate: baseTime,
          paoMonths: 12,
          notificationsEnabled: true,
          lastModified: baseTime,
        );

        final updated = item.copyWith(status: CollectionStatus.archive);

        expect(updated.openedDate, baseTime);
      });
    });

    group('equality', () {
      test('should_be_equal_when_all_fields_are_identical', () {
        /**
         * Given: Two CollectionItem instances with identical fields
         * When: == operator is used
         * Then: they should be equal
         */
        final item1 = CollectionItem(
          id: 'item-4',
          productId: 'prod-4',
          status: CollectionStatus.inUse,
          openedDate: baseTime,
          paoMonths: 12,
          notificationsEnabled: true,
          lastModified: baseTime,
        );

        final item2 = CollectionItem(
          id: 'item-4',
          productId: 'prod-4',
          status: CollectionStatus.inUse,
          openedDate: baseTime,
          paoMonths: 12,
          notificationsEnabled: true,
          lastModified: baseTime,
        );

        expect(item1, equals(item2));
      });

      test('should_have_equal_hashCode_when_all_fields_are_identical', () {
        /**
         * Given: Two CollectionItem instances with identical fields
         * When: hashCode is computed
         * Then: they should have the same hashCode
         */
        final item1 = CollectionItem(
          id: 'item-5',
          productId: 'prod-5',
          status: CollectionStatus.sealed,
          openedDate: futureTime,
          paoMonths: 18,
          notificationsEnabled: false,
          lastModified: baseTime,
        );

        final item2 = CollectionItem(
          id: 'item-5',
          productId: 'prod-5',
          status: CollectionStatus.sealed,
          openedDate: futureTime,
          paoMonths: 18,
          notificationsEnabled: false,
          lastModified: baseTime,
        );

        expect(item1.hashCode, item2.hashCode);
      });

      test('should_not_be_equal_when_status_differs', () {
        /**
         * Given: Two CollectionItem instances with different status
         * When: == operator is used
         * Then: they should not be equal
         */
        final item1 = CollectionItem(
          id: 'item-6',
          productId: 'prod-6',
          status: CollectionStatus.inUse,
          openedDate: baseTime,
          paoMonths: 12,
          notificationsEnabled: true,
          lastModified: baseTime,
        );

        final item2 = CollectionItem(
          id: 'item-6',
          productId: 'prod-6',
          status: CollectionStatus.archive,
          openedDate: baseTime,
          paoMonths: 12,
          notificationsEnabled: true,
          lastModified: baseTime,
        );

        expect(item1, isNot(equals(item2)));
      });

      test('should_not_be_equal_when_id_differs', () {
        /**
         * Given: Two CollectionItem instances with different id
         * When: == operator is used
         * Then: they should not be equal
         */
        final item1 = CollectionItem(
          id: 'item-7a',
          productId: 'prod-7',
          status: CollectionStatus.inUse,
          openedDate: baseTime,
          paoMonths: 12,
          notificationsEnabled: true,
          lastModified: baseTime,
        );

        final item2 = CollectionItem(
          id: 'item-7b',
          productId: 'prod-7',
          status: CollectionStatus.inUse,
          openedDate: baseTime,
          paoMonths: 12,
          notificationsEnabled: true,
          lastModified: baseTime,
        );

        expect(item1, isNot(equals(item2)));
      });

      test('should_not_be_equal_when_openedDate_differs', () {
        /**
         * Given: Two CollectionItem instances with different openedDate
         * When: == operator is used
         * Then: they should not be equal
         */
        final item1 = CollectionItem(
          id: 'item-8',
          productId: 'prod-8',
          status: CollectionStatus.inUse,
          openedDate: baseTime,
          paoMonths: 12,
          notificationsEnabled: true,
          lastModified: baseTime,
        );

        final item2 = CollectionItem(
          id: 'item-8',
          productId: 'prod-8',
          status: CollectionStatus.inUse,
          openedDate: futureTime,
          paoMonths: 12,
          notificationsEnabled: true,
          lastModified: baseTime,
        );

        expect(item1, isNot(equals(item2)));
      });

      test('should_not_be_equal_when_paoMonths_differs', () {
        /**
         * Given: Two CollectionItem instances with different paoMonths
         * When: == operator is used
         * Then: they should not be equal
         */
        final item1 = CollectionItem(
          id: 'item-9',
          productId: 'prod-9',
          status: CollectionStatus.inUse,
          openedDate: baseTime,
          paoMonths: 12,
          notificationsEnabled: true,
          lastModified: baseTime,
        );

        final item2 = CollectionItem(
          id: 'item-9',
          productId: 'prod-9',
          status: CollectionStatus.inUse,
          openedDate: baseTime,
          paoMonths: 18,
          notificationsEnabled: true,
          lastModified: baseTime,
        );

        expect(item1, isNot(equals(item2)));
      });
    });
  });
}
