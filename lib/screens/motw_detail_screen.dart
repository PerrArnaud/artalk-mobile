import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/motw.dart';
import '../providers/auth_provider.dart';
import '../providers/motw_provider.dart';
import '../providers/comment_provider.dart';
import '../config/api_config.dart';
import '../widgets/comment_item.dart';
import 'login_screen.dart';

class MOTWDetailScreen extends StatefulWidget {
  final String motwSlug;

  const MOTWDetailScreen({super.key, required this.motwSlug});

  @override
  State<MOTWDetailScreen> createState() => _MOTWDetailScreenState();
}

class _MOTWDetailScreenState extends State<MOTWDetailScreen> {
  MOTW? _motw;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final motwProvider = Provider.of<MOTWProvider>(context, listen: false);
    final commentProvider = Provider.of<CommentProvider>(context, listen: false);

    final motw = await motwProvider.fetchMOTWDetail(widget.motwSlug);
    await commentProvider.fetchComments(widget.motwSlug, refresh: true);

    setState(() {
      _motw = motw;
      _isLoading = false;
    });
  }

  Future<void> _handleSubmitComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a comment')),
      );
      return;
    }

    final commentProvider = Provider.of<CommentProvider>(context, listen: false);
    final success = await commentProvider.createComment(
      motwSlug: widget.motwSlug,
      content: _commentController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment posted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(commentProvider.errorMessage ?? 'Failed to post comment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artwork Details'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _motw == null
              ? const Center(child: Text('Artwork not found'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Artwork Image
                            if (_motw!.visual != null && _motw!.visual!.isNotEmpty)
                              CachedNetworkImage(
                                imageUrl: ApiConfig.getImageUrl(_motw!.visual),
                                httpHeaders: const {'ngrok-skip-browser-warning': 'true'},
                                width: double.infinity,
                                height: 250,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 250,
                                  color: Colors.grey[300],
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 250,
                                  color: Colors.grey[300],
                                  child: const Center(child: Icon(Icons.error)),
                                ),
                              ),

                            // Artwork Info
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _motw!.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'by ${_motw!.artist}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('dd MMMM yyyy').format(_motw!.date),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.publish, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Posted: ${DateFormat('dd MMM yyyy').format(_motw!.datePost)}',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const Divider(),

                            // Comments Section
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.comment, color: Colors.deepPurple),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Comments (${_motw!.commentCount})',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Consumer<CommentProvider>(
                              builder: (context, commentProvider, _) {
                                final comments = commentProvider.getComments(widget.motwSlug);

                                if (commentProvider.isLoading && comments.isEmpty) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                if (comments.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Center(
                                      child: Text(
                                        'No comments yet. Be the first to comment!',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: comments.length,
                                  itemBuilder: (context, index) {
                                    return CommentItem(
                                      comment: comments[index],
                                      motwSlug: widget.motwSlug,
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Comment Input
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        if (!authProvider.isAuthenticated) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: SafeArea(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  );
                                },
                                icon: const Icon(Icons.login),
                                label: const Text('Login to comment'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                ),
                              ),
                            ),
                          );
                        }
                        return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: SafeArea(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                maxLines: null,
                                decoration: const InputDecoration(
                                  hintText: 'Write a comment...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Consumer<CommentProvider>(
                              builder: (context, commentProvider, _) {
                                return IconButton(
                                  onPressed: commentProvider.isSubmitting
                                      ? null
                                      : _handleSubmitComment,
                                  icon: commentProvider.isSubmitting
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.send),
                                  color: Colors.deepPurple,
                                  iconSize: 28,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                      },
                    ),
                  ],
                ),
    );
  }
}
