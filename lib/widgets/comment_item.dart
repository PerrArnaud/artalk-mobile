import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/comment.dart';
import '../providers/comment_provider.dart';

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
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
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
        const SnackBar(content: Text('Reply posted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(commentProvider.errorMessage ?? 'Failed to post reply'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    child: Text(
                      widget.comment.user.name.isNotEmpty
                          ? widget.comment.user.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
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
                ],
              ),
              const SizedBox(height: 8),

              // Comment content
              Text(
                widget.comment.content,
                style: const TextStyle(fontSize: 14),
              ),

              // Reply button (only for top-level comments)
              if (!widget.isReply) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _showReplyBox = !_showReplyBox);
                  },
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Reply'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],

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
                          hintText: 'Write a reply...',
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
              if (widget.comment.replies.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...widget.comment.replies.map((reply) => CommentItem(
                      comment: reply,
                      motwSlug: widget.motwSlug,
                      isReply: true,
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
