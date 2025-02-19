import 'package:apilook/models/api_endpoint.dart';
import 'package:apilook/utils/exceptions/service_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class APIService {
  final SupabaseClient client;

  APIService(this.client);

  Future<APIEndpoint> createAPI(APIEndpoint endpoint) async {
    try {
      final response = await client
          .from('api_endpoints')
          .insert(endpoint.toJson())
          .select()
          .single();

      return APIEndpoint.fromJson(response);
    } catch (e) {
      throw ServiceException('Failed to create API: $e');
    }
  }

  Future<List<APIEndpoint>> getUserAPIs() async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw ServiceException('User not authenticated');

      final response = await client
          .from('api_endpoints')
          .select()
          .eq('user_id', userId)
          .eq('active', true)
          .order('created_at', ascending: false);

      return response.map((json) => APIEndpoint.fromJson(json)).toList();
    } catch (e) {
      throw ServiceException('Failed to fetch APIs: $e');
    }
  }
}
