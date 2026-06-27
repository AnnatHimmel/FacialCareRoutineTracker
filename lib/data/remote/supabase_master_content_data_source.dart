import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/master_content_repository.dart';
import '../cache/master_content_serializer.dart';
import 'remote_content_data_source.dart';

class SupabaseMasterContentDataSource implements RemoteContentDataSource {
  final SupabaseClient _client;

  SupabaseMasterContentDataSource(this._client);

  @override
  Future<MasterContent> fetchContent() async {
    final dynamic response = await _client.rpc<dynamic>('get_master_content');
    final json = response as Map<String, dynamic>;
    return MasterContentSerializer.fromCombinedJson(json);
  }
}
