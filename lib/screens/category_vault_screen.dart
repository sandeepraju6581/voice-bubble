import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/vault_service.dart';
import 'category_detail_screen.dart';

const List<Map<String, String>> vaultGradients = [
  {'start': '#06B6D4', 'end': '#3B82F6', 'name': 'Ocean Cyan'},
  {'start': '#8B5CF6', 'end': '#D946EF', 'name': 'Neon Violet'},
  {'start': '#F97316', 'end': '#EF4444', 'name': 'Sunset Orange'},
  {'start': '#10B981', 'end': '#059669', 'name': 'Emerald Mint'},
  {'start': '#EC4899', 'end': '#F43F5E', 'name': 'Rose Pink'},
];

const List<IconData> vaultIcons = [
  Icons.folder_rounded,
  Icons.image_rounded,
  Icons.work_rounded,
  Icons.person_rounded,
  Icons.favorite_rounded,
  Icons.star_rounded,
  Icons.lock_rounded,
];

Color parseColor(String hex) {
  final clean = hex.replaceAll('#', '');
  return Color(int.parse('FF$clean', radix: 16));
}

class CategoryVaultScreen extends StatefulWidget {
  const CategoryVaultScreen({super.key});

  @override
  State<CategoryVaultScreen> createState() => _CategoryVaultScreenState();
}

class _CategoryVaultScreenState extends State<CategoryVaultScreen> {
  final VaultService _vaultService = VaultService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "IMAGE VAULT",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
            fontFamily: 'Outfit',
          ),
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
              if (_vaultService.isLoading && _vaultService.categories.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: Colors.cyan));
              }

              final categories = _vaultService.categories;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildVaultHeader(),
                  Expanded(
                    child: RefreshIndicator(
                      color: Colors.cyan,
                      onRefresh: () => _vaultService.loadCategories(),
                      child: categories.isEmpty
                          ? _buildEmptyState()
                          : GridView.builder(
                              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.88,
                              ),
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                return _buildCategoryCard(categories[index]);
                              },
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context),
        backgroundColor: Colors.cyan[600],
        icon: const Icon(Icons.create_new_folder_rounded, color: Colors.white),
        label: const Text(
          "New Folder",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildVaultHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.purpleAccent.withValues(alpha: 0.1),
            Colors.cyan.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_shared_rounded, color: Colors.cyan[400], size: 24),
              const SizedBox(width: 8),
              const Text(
                "Categorized Image Vault",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Organize images into folders. Tap folders to view, or use the direct buttons on cards to instantly share or copy all stored images.",
            style: TextStyle(fontSize: 12, color: Colors.white60, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.55,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_rounded, size: 70, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              "No Folders Yet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            const Text(
              "Tap 'New Folder' to begin storing images.",
              style: TextStyle(fontSize: 13, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(VaultCategory category) {
    final startColor = parseColor(category.colorStart);
    final endColor = parseColor(category.colorEnd);
    final folderIcon = getCategoryIcon(category.iconCodePoint);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Material(
          color: Colors.white.withValues(alpha: 0.03),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryDetailScreen(category: category),
                ),
              );
            },
            onLongPress: () => _showCategoryOptions(context, category),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon & Action Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [startColor, endColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: startColor.withValues(alpha: 0.3),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(folderIcon, color: Colors.white, size: 22),
                      ),
                      // Top actions: Copy & Share
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy_all_rounded, color: Colors.cyan, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: "Copy all images",
                            onPressed: category.imagePaths.isEmpty
                                ? () => _showEmptyFolderAlert(context)
                                : () async {
                                    final success = await _vaultService.copyCategoryToClipboard(category);
                                    if (success && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("Copied images from '${category.name}' to clipboard!"),
                                          backgroundColor: Colors.cyan[800],
                                        ),
                                      );
                                    }
                                  },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send_rounded, color: Color(0xFF25D366), size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: "Send to WhatsApp",
                            onPressed: category.imagePaths.isEmpty
                                ? () => _showEmptyFolderAlert(context)
                                : () async {
                                    final success = await _vaultService.sendCategoryToWhatsApp(category);
                                    if (!success && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("WhatsApp is not installed!"),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.share_rounded, color: Colors.purpleAccent, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: "Share folder",
                            onPressed: category.imagePaths.isEmpty
                                ? () => _showEmptyFolderAlert(context)
                                : () => _vaultService.shareCategory(category),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Name and count
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "${category.imagePaths.length} ${category.imagePaths.length == 1 ? 'image' : 'images'}",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEmptyFolderAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("This folder is empty. Open it to add images!"),
        backgroundColor: Colors.amber,
      ),
    );
  }

  void _showCategoryOptions(BuildContext context, VaultCategory category) {
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
                leading: const Icon(Icons.edit_rounded, color: Colors.cyan),
                title: const Text("Rename & Customize"),
                onTap: () {
                  Navigator.pop(context);
                  _showEditCategoryDialog(context, category);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text("Delete Folder"),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(context, category);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, VaultCategory category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF14123A),
          title: Text("Delete '${category.name}'?"),
          content: Text(
            "This will permanently delete this folder and all ${category.imagePaths.length} image(s) inside it.",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _vaultService.deleteCategory(category.id);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    int selectedGradientIdx = 0;
    int selectedIconIdx = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF14123A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Create Folder", style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        labelText: "Folder Name",
                        labelStyle: TextStyle(color: Colors.white54),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text("Color Scheme", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: vaultGradients.length,
                        itemBuilder: (context, idx) {
                          final grad = vaultGradients[idx];
                          final colorS = parseColor(grad['start']!);
                          final colorE = parseColor(grad['end']!);
                          final isSelected = selectedGradientIdx == idx;

                          return GestureDetector(
                            onTap: () => setModalState(() => selectedGradientIdx = idx),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [colorS, colorE]),
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 2.5)
                                    : Border.all(color: Colors.transparent),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Folder Icon", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: vaultIcons.length,
                        itemBuilder: (context, idx) {
                          final icon = vaultIcons[idx];
                          final isSelected = selectedIconIdx == idx;

                          return GestureDetector(
                            onTap: () => setModalState(() => selectedIconIdx = idx),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.cyan.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.cyan, width: 1.5)
                                    : Border.all(color: Colors.transparent),
                              ),
                              child: Icon(icon, color: isSelected ? Colors.cyan : Colors.white70, size: 18),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      final grad = vaultGradients[selectedGradientIdx];
                      await _vaultService.createCategory(
                        name: name,
                        colorStart: grad['start']!,
                        colorEnd: grad['end']!,
                        iconCodePoint: vaultIcons[selectedIconIdx].codePoint,
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text("Create", style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditCategoryDialog(BuildContext context, VaultCategory category) {
    final nameController = TextEditingController(text: category.name);
    
    int selectedGradientIdx = vaultGradients.indexWhere((g) => g['start'] == category.colorStart);
    if (selectedGradientIdx == -1) selectedGradientIdx = 0;

    int selectedIconIdx = vaultIcons.indexWhere((i) => i.codePoint == category.iconCodePoint);
    if (selectedIconIdx == -1) selectedIconIdx = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF14123A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Edit Folder", style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        labelText: "Folder Name",
                        labelStyle: TextStyle(color: Colors.white54),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text("Color Scheme", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: vaultGradients.length,
                        itemBuilder: (context, idx) {
                          final grad = vaultGradients[idx];
                          final colorS = parseColor(grad['start']!);
                          final colorE = parseColor(grad['end']!);
                          final isSelected = selectedGradientIdx == idx;

                          return GestureDetector(
                            onTap: () => setModalState(() => selectedGradientIdx = idx),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [colorS, colorE]),
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 2.5)
                                    : Border.all(color: Colors.transparent),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Folder Icon", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: vaultIcons.length,
                        itemBuilder: (context, idx) {
                          final icon = vaultIcons[idx];
                          final isSelected = selectedIconIdx == idx;

                          return GestureDetector(
                            onTap: () => setModalState(() => selectedIconIdx = idx),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.cyan.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.cyan, width: 1.5)
                                    : Border.all(color: Colors.transparent),
                              ),
                              child: Icon(icon, color: isSelected ? Colors.cyan : Colors.white70, size: 18),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      final grad = vaultGradients[selectedGradientIdx];
                      await _vaultService.updateCategory(
                        id: category.id,
                        name: name,
                        colorStart: grad['start']!,
                        colorEnd: grad['end']!,
                        iconCodePoint: vaultIcons[selectedIconIdx].codePoint,
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text("Save", style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
