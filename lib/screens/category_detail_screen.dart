import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/vault_service.dart';
import 'category_vault_screen.dart'; // for parseColor helper

class CategoryDetailScreen extends StatefulWidget {
  final VaultCategory category;
  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final VaultService _vaultService = VaultService.instance;
  final ImagePicker _picker = ImagePicker();
  late String _categoryId;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.category.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: AnimatedBuilder(
          animation: _vaultService,
          builder: (context, _) {
            final cat = _getCurrentCategory();
            return Text(
              cat.name.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.white,
                fontFamily: 'Outfit',
              ),
            );
          },
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D0B21),
              Color(0xFF14123A),
              Color(0xFF1F124C),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _vaultService,
            builder: (context, _) {
              final cat = _getCurrentCategory();
              final images = cat.imagePaths;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (images.isNotEmpty) _buildActionHeader(cat),
                  Expanded(
                    child: images.isEmpty
                        ? _buildEmptyState()
                        : GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: images.length,
                            itemBuilder: (context, index) {
                              return _buildImageCard(cat, images[index], index);
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showImageSourceSheet(context),
        backgroundColor: Colors.cyan[600],
        child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
      ),
    );
  }

  VaultCategory _getCurrentCategory() {
    try {
      return _vaultService.categories.firstWhere((c) => c.id == _categoryId);
    } catch (_) {
      return VaultCategory(
        id: _categoryId,
        name: widget.category.name,
        colorStart: widget.category.colorStart,
        colorEnd: widget.category.colorEnd,
        iconCodePoint: widget.category.iconCodePoint,
        createdAt: widget.category.createdAt,
        imagePaths: [],
      );
    }
  }

  Widget _buildActionHeader(VaultCategory cat) {
    final endColor = parseColor(cat.colorEnd);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "${cat.imagePaths.length} Images Saved",
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              // Copy Button
              ElevatedButton.icon(
                onPressed: () async {
                  final success = await _vaultService.copyCategoryToClipboard(cat);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Copied all images to clipboard!"),
                        backgroundColor: Colors.cyan[800],
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan[700]!.withValues(alpha: 0.2),
                  foregroundColor: Colors.cyanAccent,
                  shadowColor: Colors.transparent,
                  side: const BorderSide(color: Colors.cyan, width: 0.8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.copy_all_rounded, size: 16),
                label: const Text("Copy All", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              // WhatsApp Button
              ElevatedButton.icon(
                onPressed: () async {
                  final success = await _vaultService.sendCategoryToWhatsApp(cat);
                  if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("WhatsApp is not installed!"),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.2),
                  foregroundColor: const Color(0xFF25D366),
                  shadowColor: Colors.transparent,
                  side: const BorderSide(color: Color(0xFF25D366), width: 0.8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text("WhatsApp", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              // Share Button
              ElevatedButton.icon(
                onPressed: () => _vaultService.shareCategory(cat),
                style: ElevatedButton.styleFrom(
                  backgroundColor: endColor.withValues(alpha: 0.2),
                  foregroundColor: Colors.purpleAccent,
                  shadowColor: Colors.transparent,
                  side: BorderSide(color: endColor, width: 0.8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text("Share All", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 50, color: Colors.cyan[300]),
            const SizedBox(height: 12),
            const Text(
              "Folder is Empty",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              "Tap the + button to select images from your gallery or capture a photo directly.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white54, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(VaultCategory cat, String path, int index) {
    return GestureDetector(
      onTap: () => _openFullscreenImage(cat, index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'img_hero_${cat.id}_$index',
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.white12,
                  child: const Icon(Icons.broken_image, color: Colors.white30),
                ),
              ),
            ),
            // Delete button overlay
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _confirmDeleteImage(cat.id, path),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.redAccent,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14123A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Colors.cyan),
                title: const Text("Select from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickGalleryImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.cyan),
                title: const Text("Take a Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _captureCameraPhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickGalleryImages() async {
    try {
      final List<XFile> selected = await _picker.pickMultiImage();
      if (selected.isNotEmpty) {
        await _vaultService.addImagesToCategory(
          _categoryId,
          selected.map((x) => x.path).toList(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking images: $e")),
        );
      }
    }
  }

  Future<void> _captureCameraPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        await _vaultService.addImagesToCategory(_categoryId, [photo.path]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error capturing photo: $e")),
        );
      }
    }
  }

  void _confirmDeleteImage(String catId, String path) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF14123A),
          title: const Text("Delete Image?"),
          content: const Text("Are you sure you want to remove this image from the folder?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _vaultService.deleteImage(catId, path);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  void _openFullscreenImage(VaultCategory cat, int initialIdx) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenImageScreen(
          category: cat,
          initialIndex: initialIdx,
        ),
      ),
    );
  }
}

class FullscreenImageScreen extends StatefulWidget {
  final VaultCategory category;
  final int initialIndex;

  const FullscreenImageScreen({
    super.key,
    required this.category,
    required this.initialIndex,
  });

  @override
  State<FullscreenImageScreen> createState() => _FullscreenImageScreenState();
}

class _FullscreenImageScreenState extends State<FullscreenImageScreen> {
  late PageController _pageController;
  late int _currentIndex;
  final VaultService _vaultService = VaultService.instance;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${_currentIndex + 1} of ${widget.category.imagePaths.length}",
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: () => _confirmDeleteCurrentImage(),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.category.imagePaths.length,
        onPageChanged: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
        itemBuilder: (context, idx) {
          final path = widget.category.imagePaths[idx];
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.0,
            child: Center(
              child: Hero(
                tag: 'img_hero_${widget.category.id}_$idx',
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    color: Colors.white30,
                    size: 64,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteCurrentImage() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF14123A),
          title: const Text("Delete Image?"),
          content: const Text("Are you sure you want to remove this image from the folder?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Pop dialog
                final path = widget.category.imagePaths[_currentIndex];
                
                final navigator = Navigator.of(context);
                await _vaultService.deleteImage(widget.category.id, path);
                
                if (widget.category.imagePaths.length <= 1) {
                  // No images left, close fullscreen view
                  navigator.pop();
                } else {
                  // Move to previous/next image
                  final nextIdx = _currentIndex > 0 ? _currentIndex - 1 : 0;
                  setState(() {
                    _currentIndex = nextIdx;
                  });
                  _pageController.jumpToPage(nextIdx);
                }
              },
              child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }
}
