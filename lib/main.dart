import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/local/database/app_database.dart';
import 'shared/providers/root_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = openDatabase();
  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const SkincareApp(),
    ),
  );
}
