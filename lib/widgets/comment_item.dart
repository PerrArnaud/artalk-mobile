import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import '../models/comment.dart';
import '../providers/auth_provider.dart';
import '../providers/comment_provider.dart';

/// Number of replies shown before the "Show more" button appears.
const int _kRepliesThreshold = 5;

/// Predefined report reasons matching the backend's Report::REASONS constant.
const Map<String, String> _kReportReasons = {
  'spam': 'Spam',
  'harcelement': 'Harcèlement',
  'contenu_inapproprie': 'Contenu inapproprié',
  'desinformation': 'Désinformation',
  'autre': 'Autre',
};

class CommentItem extends StatefulWidget {
  final Comment comment;
  final String motwSlug;
  final bool isReply;

  const CommentItem({
    super.key,
    required this.comment,
    required this.motwSlug,
    this.isReply = false,
  });

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  bool _showReplyBox = false;
  bool _showAllReplies = false;
  bool _isLiking = false;
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _handleLike() async {
    if (_isLiking) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour liker un commentaire')),
      );
      return;
    }

    setState(() => _isLiking = true);

    final commentProvider = Provider.of<CommentProvider>(context, listen: false);
    await commentProvider.likeComment(
      commentId: widget.comment.id,
      motwSlug: widget.motwSlug,
    );

    if (mounted) setState(() => _isLiking = false);
  }

  Future<void> _handleReply() async {
    if (_replyController.text.trim().isEmpty) return;

    final commentProvider = Provider.of<CommentProvider>(context, listen: false);
    final success = await commentProvider.createComment(
      motwSlug: widget.motwSlug,
      content: _replyController.text.trim(),
      parentCommentId: widget.comment.id,
    );

    if (!mounted) return;

    if (success) {
      _replyController.clear();
      setState(() => _showReplyBox = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réponse publiée avec succès')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(commentProvider.errorMessage ?? 'Échec de la publication'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleReport() async {
    String? selectedReason;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Signaler ce commentaire'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choisissez une raison :'),
              const SizedBox(height: 12),
              ..._kReportReasons.entries.map(
                (entry) => RadioListTile<String>(
                  value: entry.key,
                  groupValue: selectedReason,
                  title: Text(entry.value),
                  dense: true,
                  onChanged: (v) => setStateDialog(() => selectedReason = v),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: selectedReason == null
                  ? null
                  : () => Navigator.of(ctx).pop(true),
              child: const Text('Signaler'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selectedReason == null || !mounted) return;

    final commentProvider = Provider.of<CommentProvider>(context, listen: false);
    final success = await commentProvider.reportComment(
      commentId: widget.comment.id,
      reason: selectedReason!,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commentaire signalé. Merci !')),
      );
    } else {
      final msg = commentProvider.errorMessage ?? 'Échec du signalement';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final isOwnComment = currentUser != null &&
        currentUser.id == widget.comment.user.id;
    final canReport = authProvider.isAuthenticated && !isOwnComment;

    final replies = widget.comment.replies;
    final visibleReplies = (!_showAllReplies && replies.length > _kRepliesThreshold)
        ? replies.sublist(0, _kRepliesThreshold)
        : replies;
    final hiddenCount = replies.length - _kRepliesThreshold;

    return Container(
      margin: EdgeInsets.only(
        left: widget.isReply ? 48 : 16,
        right: 16,
        bottom: 8,
      ),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: widget.isReply ? Colors.grey[300]! : Colors.transparent,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info and date
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.deepPurple,
                    backgroundImage: widget.comment.user.avatar != null &&
                            widget.comment.user.avatar!.isNotEmpty
                        ? CachedNetworkImageProvider(
                            ApiConfig.getImageUrl(widget.comment.user.avatar),
                          )
                        : null,
                    child: (widget.comment.user.avatar == null ||
                            widget.comment.user.avatar!.isEmpty)
                        ? Text(
                            widget.comment.user.name.isNotEmpty
                                ? widget.comment.user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.comment.user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy HH:mm').format(widget.comment.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Report button
                  if (canReport)
                    IconButton(
                      onPressed: widget.comment.reportedByCurrentUser
                          ? null
                          : _handleReport,
                      icon: Icon(
                        Icons.flag_outlined,
                        size: 18,
                        color: widget.comment.reportedByCurrentUser
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                      tooltip: widget.comment.reportedByCurrentUser
                          ? 'Déjà signalé'
                          : 'Signaler',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Comment content
              Text(
                widget.comment.content,
                style: const TextStyle(fontSize: 14),
              ),

              // Action row: like + reply
              const SizedBox(height: 4),
              Row(
                children: [
                  // Like button
                  Consumer<CommentProvider>(
                    builder: (context, commentProvider, _) {
                      final comment = commentProvider
                          .getComments(widget.motwSlug)
                          .expand((c) => [c, ...c.replies])
                          .firstWhere((c) => c.id == widget.comment.id,
                              orElse: () => widget.comment);
                      return InkWell(
                        onTap: _isLiking ? null : _handleLike,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _isLiking
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 1.5),
                                    )
                                  : Icon(
                                      comment.likedByCurrentUser
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 16,
                                      color: comment.likedByCurrentUser
                                          ? Colors.red
                                          : Colors.grey[600],
                                    ),
                              if (comment.likesCount > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '${comment.likesCount}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: comment.likedByCurrentUser
                                        ? Colors.red
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  // Reply button (only for top-level comments)
                  if (!widget.isReply)
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _showReplyBox = !_showReplyBox);
                      },
                      icon: const Icon(Icons.reply, size: 16),
                      label: const Text('Répondre'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),

              // Reply input box
              if (_showReplyBox) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Écrire une réponse...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(8),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Consumer<CommentProvider>(
                      builder: (context, commentProvider, _) {
                        return IconButton(
                          onPressed: commentProvider.isSubmitting
                              ? null
                              : _handleReply,
                          icon: commentProvider.isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send),
                          iconSize: 20,
                        );
                      },
                    ),
                  ],
                ),
              ],

              // Replies
              if (replies.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...visibleReplies.map((reply) => CommentItem(
                      comment: reply,
                      motwSlug: widget.motwSlug,
                      isReply: true,
                    )),

                // "Show more replies" button
                if (!_showAllReplies && hiddenCount > 0)
                  TextButton.icon(
                    onPressed: () => setState(() => _showAllReplies = true),
                    icon: const Icon(Icons.expand_more, size: 16),
                    label: Text('Voir $hiddenCount autre${hiddenCount > 1 ? 's' : ''} réponse${hiddenCount > 1 ? 's' : ''}'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(left: 48),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),

                // "Hide replies" button when expanded
                if (_showAllReplies && replies.length > _kRepliesThreshold)
                  TextButton.icon(
                    onPressed: () => setState(() => _showAllReplies = false),
                    icon: const Icon(Icons.expand_less, size: 16),
                    label: const Text('Masquer les réponses'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(left: 48),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
