import 'dart:js_interop';
import 'package:drift/src/web/wasm_setup/dedicated_worker.dart';
import 'package:drift/src/web/wasm_setup/shared_worker.dart';
import 'package:web/web.dart';

void main() {
  final context = globalContext;
  if (context.isA<SharedWorkerGlobalScope>()) {
    SharedDriftWorker(context as SharedWorkerGlobalScope, null).start();
  } else {
    DedicatedDriftWorker(context as DedicatedWorkerGlobalScope, null).start();
  }
}
