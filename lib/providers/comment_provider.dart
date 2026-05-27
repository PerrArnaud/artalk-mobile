import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';

enum CommentSortOrder { recent, likes }

class CommentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  final Map<String, List<Comment>> _commentsByMotw = {};
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  CommentSortOrder _sortOrder = CommentSortOrder.recent;

  List<Comment> getComments(String motwSlug) {
    return _commentsByMotw[motwSlug] ?? [];
  }

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  CommentSortOrder get sortOrder => _sortOrder;

  void setSortOrder(String motwSlug, CommentSortOrder order) {
    if (_sortOrder == order) return;
    _sortOrder = order;
    notifyListeners();
    fetchComments(motwSlug, refresh: true);
  }

  Future<void> fetchComments(String motwSlug, {bool refresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final sortParam = _sortOrder == CommentSortOrder.likes ? 'likes' : 'recent';
      final url = '${ApiConfig.motwCommentsUrl(motwSlug)}?page=1&limit=50&sort=$sortParam';
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

  Future<bool> likeComment({
    required int commentId,
    required String motwSlug,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.likeCommentUrl(commentId),
        {},
        includeAuth: true,
      );

      final data = await _apiService.handleResponse(response);

      if (data['success'] == true) {
        final liked = data['liked'] as bool;
        final likesCount = data['likesCount'] as int;

        _updateCommentLike(motwSlug, commentId, liked: liked, likesCount: likesCount);
        notifyListeners();
        return true;
      }

      _errorMessage = data['message'] as String? ?? 'Échec du like';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _updateCommentLike(String motwSlug, int commentId, {required bool liked, required int likesCount}) {
    final comments = _commentsByMotw[motwSlug];
    if (comments == null) return;

    _commentsByMotw[motwSlug] = comments.map((c) {
      if (c.id == commentId) {
        return c.copyWith(likedByCurrentUser: liked, likesCount: likesCount);
      }
      final updatedReplies = c.replies.map((r) {
        if (r.id == commentId) {
          return r.copyWith(likedByCurrentUser: liked, likesCount: likesCount);
        }
        return r;
      }).toList();
      return c.copyWith(replies: updatedReplies);
    }).toList();
  }

  Future<bool> reportComment({
    required int commentId,
    required String reason,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        ApiConfig.reportCommentUrl(commentId),
        {'reason': reason},
        includeAuth: true,
      );

      final data = await _apiService.handleResponse(response);

      if (data['success'] == true) {
        // Mark the comment as reported locally so the UI updates immediately
        for (final entry in _commentsByMotw.entries) {
          final updated = entry.value.map((c) {
            if (c.id == commentId) {
              return c.copyWith(reportedByCurrentUser: true);
            }
            final updatedReplies = c.replies.map((r) {
              return r.id == commentId
                  ? r.copyWith(reportedByCurrentUser: true)
                  : r;
            }).toList();
            return c.copyWith(replies: updatedReplies);
          }).toList();
          _commentsByMotw[entry.key] = updated;
        }
        _isSubmitting = false;
        notifyListeners();
        return true;
      }

      _errorMessage = data['message'] as String? ?? 'Échec du signalement';
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
}
