import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/data/remote/scrapers/yes_style_scraper.dart';

void main() {
  test('LIVE yesstyle by barcode', () async {
    final r = await YesStyleScraper().search('8809820688618');
    // ignore: avoid_print
    print('BARCODE => name=${r?.name} brand=${r?.brand} img=${r?.imageUrls}');
  });
  test('LIVE yesstyle by name', () async {
    final r = await YesStyleScraper().search('beauty of joseon relief sun');
    // ignore: avoid_print
    print('NAME => name=${r?.name} brand=${r?.brand} img=${r?.imageUrls}');
  });
}
