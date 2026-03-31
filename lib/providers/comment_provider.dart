import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';

class CommentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  final Map<String, List<Comment>> _commentsByMotw = {};
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<Comment> getComments(String motwSlug) {
    return _commentsByMotw[motwSlug] ?? [];
  }

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> fetchComments(String motwSlug, {bool refresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = '${ApiConfig.motwCommentsUrl(motwSlug)}?page=1&limit=50';
      final response = await _apiService.get(url);
      
      final data = await _apiService.handleResponse(response);
      
      if (data['success'] == true && data['data'] != null) {
        final List<dynamic> commentData = data['data'] as List<dynamic>;
        final comments = commentData
            .map((json) => Comment.fromJson(json as Map<String, dynamic>))
            .toList();
        
        _commentsByMotw[motwSlug] = comments;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createComment({
    required String motwSlug,
    required String content,
    int? parentCommentId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'motwSlug': motwSlug,
        'content': content,
        if (parentCommentId != null) 'parentCommentId': parentCommentId,
      };

      final response = await _apiService.post(
        ApiConfig.commentsUrl,
        body,
        includeAuth: true,
      );
      
      final data = await _apiService.handleResponse(response);
      
      if (data['success'] == true) {
        // Refresh comments after successful creation
        await fetchComments(motwSlug, refresh: true);
        _isSubmitting = false;
        notifyListeners();
        return true;
      }
      
      _errorMessage = data['message'] as String? ?? 'Failed to create comment';
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
