import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../models/request_model.dart';

class RequestService {
  final supabase = SupabaseConfig.supabase;

  Future<void> saveRequest(RequestModel request) async {
    await supabase.from('requests').insert(request.toJson());
  }

  Future<List<Future<List<RequestModel>>>> getRequests() async {
    final response = await supabase
        .from('requests')
        .select()
        .order('created_at', ascending: false);

    return response.map((json) => RequestModel.fromJson(json)).toList();
  }
}
