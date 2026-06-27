import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/assessment_model.dart';

final assessmentListProvider = FutureProvider<List<Assessment>>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('assessments')
        .select()
        .eq('is_published', true)
        .order('title', ascending: true);

    return (response as List).map((json) => Assessment.fromJson(json as Map<String, dynamic>)).toList();
  } catch (e) {
    if (kDebugMode) {
      print('assessmentListProvider: Error fetching assessments: $e');
    }
    rethrow;
  }
});

final assessmentDetailProvider = FutureProvider.family<Assessment?, String>((ref, slug) async {
  try {
    final response = await Supabase.instance.client
        .from('assessments')
        .select()
        .eq('slug', slug)
        .eq('is_published', true)
        .maybeSingle();

    if (response == null) return null;
    return Assessment.fromJson(response);
  } catch (e) {
    if (kDebugMode) {
      print('assessmentDetailProvider: Error fetching assessment ($slug): $e');
    }
    rethrow;
  }
});
