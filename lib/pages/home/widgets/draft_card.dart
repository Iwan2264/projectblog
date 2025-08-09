import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';

import '../../../models/blog_post_model.dart';
import '../../../controllers/blog_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../blog/create_post_page.dart';

class DraftsGrid extends StatefulWidget {
  const DraftsGrid({super.key});

  @override
  State<DraftsGrid> createState() => _DraftsGridState();
}

class _DraftsGridState extends State<DraftsGrid> {
  final BlogController _blogController = Get.find<BlogController>();
  final AuthController _authController = Get.find<AuthController>();
  
  bool _isLoading = true;
  int _displayCount = 6;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    setState(() => _isLoading = true);
    
    final currentUser = _authController.userModel.value;
    if (currentUser != null) {
      await _blogController.loadUserDrafts(currentUser.uid);
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_isLoading) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      
      final currentUser = _authController.userModel.value;
      final drafts = currentUser != null
          ? _blogController.userDrafts
              .where((draft) => draft.authorId == currentUser.uid)
              .toList()
          : [];
              
      if (drafts.isEmpty) {
        return _buildEmptyState();
      }
      
      return RefreshIndicator(
        onRefresh: _loadDrafts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildGridView(drafts.cast<BlogPostModel>()),
              if (_displayCount < drafts.length) _buildLoadMoreButton(drafts.length),
              // Add bottom padding to ensure the grid doesn't overflow
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    });
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.drafts_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            "You have no saved drafts.",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Start writing to save your first draft!",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<BlogPostModel> drafts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: min(_displayCount, drafts.length),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) {
          final draft = drafts[index];
          return _buildDraftCard(draft);
        },
      ),
    );
  }

  Widget _buildLoadMoreButton(int totalDrafts) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _displayCount = min(_displayCount + 6, totalDrafts);
          });
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        ),
        child: Text('Load More (${totalDrafts - _displayCount} remaining)'),
      ),
    );
  }

  Widget _buildDraftCard(BlogPostModel draft) {
    return GestureDetector(
      onTap: () => _editDraft(draft),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.all(3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                child: draft.imageURL != null && draft.imageURL!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: draft.imageURL!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft.title.isNotEmpty ? draft.title : 'Untitled Draft',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          _getContentPreview(draft.content),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatDate(draft.updatedAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      draft.category,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getContentPreview(String content) {
    // Remove HTML tags and get preview
    String plainText = content.replaceAll(RegExp(r'<[^>]*>'), '');
    if (plainText.length > 60) {
      return '${plainText.substring(0, 60)}...';
    }
    return plainText;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _editDraft(BlogPostModel draft) {
    Get.to(() => CreatePostPage(draftId: draft.id));
  }
}
