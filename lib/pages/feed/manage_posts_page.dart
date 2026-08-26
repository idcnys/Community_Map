import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/utils/time_ago.dart';
import '../../models/community_post_model.dart';
import '../../providers/service_providers.dart';
import '../../providers/feed_providers.dart';
import '../../services/cloudinary_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'comments_page.dart';

class ManagePostsPage extends ConsumerStatefulWidget {
  const ManagePostsPage({super.key});

  @override
  ConsumerState<ManagePostsPage> createState() => _ManagePostsPageState();
}

class _ManagePostsPageState extends ConsumerState<ManagePostsPage> {
  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('আমার পোস্ট পরিচালনা')),
      body: StreamBuilder<List<CommunityPostModel>>(
        stream: ref.read(postServiceProvider).getMyPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.fileText, size: 64, color: theme.colorScheme.onSurfaceVariant.withAlpha(150)),
                  const SizedBox(height: 12),
                  Text('এখনো কোনো পোস্ট নেই', style: TextStyle(fontFamily: 'EkusheInter', color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            itemBuilder: (ctx, i) {
              final post = posts[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(
                    post.isPoll ? LucideIcons.barChart2 : LucideIcons.fileText,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'EkusheInter', fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        timeAgo(post.createdAt ?? DateTime.now()),
                        style: TextStyle(fontFamily: 'EkusheInter', fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(LucideIcons.eye, size: 20, color: theme.colorScheme.onSurfaceVariant),
                        tooltip: 'মন্তব্য দেখুন',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CommentsPage(
                              postId: post.id,
                              postAuthorId: post.authorId,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.pencil, size: 20, color: theme.colorScheme.primary),
                        onPressed: () => _editPost(post),
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.trash2, size: 20, color: theme.colorScheme.error),
                        onPressed: () => _confirmDelete(post),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _editPost(CommunityPostModel post) {
    final titleCtrl = TextEditingController(text: post.title);
    final descCtrl = TextEditingController(text: post.description);
    final picker = ImagePicker();
    final cloudinary = CloudinaryService();

    // Track image state: existing URL, newly picked file, or removed
    String? currentImageUrl = post.imageUrl.isNotEmpty ? post.imageUrl : null;
    File? newImageFile;
    bool imageRemoved = false;
    bool uploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final modalTheme = Theme.of(ctx);
          // Determine what to show in the image preview area
          Widget? imagePreview;
          if (newImageFile != null) {
            imagePreview = ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(newImageFile!, height: 150, fit: BoxFit.cover),
            );
          } else if (!imageRemoved && currentImageUrl != null) {
            imagePreview = ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: currentImageUrl,
                height: 150,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  height: 150,
                  color: modalTheme.colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('পোস্ট সম্পাদনা', style: Theme.of(ctx).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'শিরোনাম'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'বিবরণ'),
                    ),
                    const SizedBox(height: 12),
                    // ── Image section ──
                    if (imagePreview != null) ...[
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          imagePreview,
                          Positioned(
                            top: -8,
                            right: -8,
                            child: IconButton.filledTonal(
                              iconSize: 16,
                              onPressed: () => setModalState(() {
                                newImageFile = null;
                                imageRemoved = true;
                              }),
                              icon: const Icon(LucideIcons.x),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: uploading
                              ? null
                              : () async {
                                  final source = await showModalBottomSheet<String>(
                                    context: ctx,
                                    builder: (c) => SafeArea(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            leading: const Icon(LucideIcons.camera),
                                            title: const Text('ক্যামেরা'),
                                            onTap: () => Navigator.of(c).pop('camera'),
                                          ),
                                          ListTile(
                                            leading: const Icon(LucideIcons.image),
                                            title: const Text('গ্যালারি'),
                                            onTap: () => Navigator.of(c).pop('gallery'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                  if (source == null) return;
                                  final picked = await picker.pickImage(
                                    source: source == 'camera'
                                        ? ImageSource.camera
                                        : ImageSource.gallery,
                                    maxWidth: 1600,
                                    maxHeight: 1600,
                                    imageQuality: 85,
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      newImageFile = File(picked.path);
                                      imageRemoved = false;
                                    });
                                  }
                                },
                          icon: const Icon(LucideIcons.imagePlus, size: 18),
                          label: Text(newImageFile != null || (!imageRemoved && currentImageUrl != null)
                              ? 'ছবি পরিবর্তন করুন'
                              : 'ছবি যোগ করুন'),
                        ),
                        if (uploading) ...[
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: uploading
                          ? null
                          : () async {
                              setModalState(() => uploading = true);
                              try {
                                String? newUrl;
                                if (newImageFile != null) {
                                  newUrl = await cloudinary.uploadImage(
                                    newImageFile!,
                                    folder: 'cmap/community',
                                    onError: (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('ছবি আপলোড ব্যর্থ: $e')),
                                        );
                                      }
                                    },
                                  );
                                }

                                Navigator.of(ctx).pop();
                                await ref.read(postServiceProvider).updatePost(
                                  post.id,
                                  title: titleCtrl.text.trim(),
                                  description: descCtrl.text.trim(),
                                  imageUrl: newUrl,
                                  removeImage: imageRemoved && newImageFile == null,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('পোস্ট আপডেট হয়েছে')),
                                  );
                                }
                              } finally {
                                setModalState(() => uploading = false);
                              }
                            },
                      child: Text(uploading ? 'সংরক্ষণ হচ্ছে…' : 'পরিবর্তন সংরক্ষণ করুন'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(CommunityPostModel post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('পোস্ট মুছুন'),
        content: Text('"${post.title}" মুছবেন? এটি পূর্বাবস্থায় ফেরানো যাবে না।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(postServiceProvider).deletePost(post.id);
              ref.read(paginatedFeedProvider.notifier).removePost(post.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('পোস্ট মুছে গেছে')),
                );
              }
            },
            child: const Text('মুছুন'),
          ),
        ],
      ),
    );
  }
}
