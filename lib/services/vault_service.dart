import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:local_clipboard/local_clipboard.dart';

const List<IconData> vaultIcons = [
  Icons.folder_rounded,
  Icons.image_rounded,
  Icons.work_rounded,
  Icons.person_rounded,
  Icons.favorite_rounded,
  Icons.star_rounded,
  Icons.lock_rounded,
];

IconData getCategoryIcon(int codePoint) {
  for (final icon in vaultIcons) {
    if (icon.codePoint == codePoint) {
      return icon;
    }
  }
  return Icons.folder_rounded;
}


class VaultCategory {
  final String id;
  final String name;
  final String colorStart;
  final String colorEnd;
  final int iconCodePoint;
  final DateTime createdAt;
  final List<String> imagePaths;

  VaultCategory({
    required this.id,
    required this.name,
    required this.colorStart,
    required this.colorEnd,
    required this.iconCodePoint,
    required this.createdAt,
    required this.imagePaths,
  });

  factory VaultCategory.fromJson(Map<String, dynamic> json, String id, List<String> imagePaths) {
    return VaultCategory(
      id: id,
      name: json['name'] ?? 'Unnamed',
      colorStart: json['colorStart'] ?? '#06B6D4', // default cyan
      colorEnd: json['colorEnd'] ?? '#3B82F6', // default blue
      iconCodePoint: json['iconCodePoint'] ?? 57586, // default Icons.folder code point
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      imagePaths: imagePaths,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'colorStart': colorStart,
      'colorEnd': colorEnd,
      'iconCodePoint': iconCodePoint,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class VaultService extends ChangeNotifier {
  VaultService._internal() {
    loadCategories();
  }
  static final VaultService instance = VaultService._internal();

  List<VaultCategory> _categories = [];
  List<VaultCategory> get categories => _categories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<Directory> get _vaultDir async {
    String? path;
    try {
      final docs = await getApplicationDocumentsDirectory();
      path = docs.path;
    } catch (e) {
      if (Platform.isAndroid) {
        path = '/data/user/0/com.example.viocebubble/app_flutter';
      } else {
        rethrow;
      }
    }
    final vault = Directory('$path/vault');
    if (!await vault.exists()) {
      await vault.create(recursive: true);
    }
    return vault;
  }

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final vault = await _vaultDir;
      final List<VaultCategory> loaded = [];

      final entities = await vault.list().toList();
      for (final entity in entities) {
        if (entity is Directory) {
          final id = entity.path.split(Platform.pathSeparator).last;
          
          // Read metadata
          final metaFile = File('${entity.path}/metadata.json');
          Map<String, dynamic> json = {};
          if (await metaFile.exists()) {
            try {
              json = jsonDecode(await metaFile.readAsString());
            } catch (e) {
              // Ignore decode issues
            }
          }

          // Read image paths
          final files = await entity.list().toList();
          final List<String> imagePaths = [];
          for (final f in files) {
            if (f is File && _isImageFile(f.path)) {
              imagePaths.add(f.path);
            }
          }

          imagePaths.sort();
          loaded.add(VaultCategory.fromJson(json, id, imagePaths));
        }
      }

      loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _categories = loaded;
    } catch (e) {
      if (kDebugMode) print("Error loading categories: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isImageFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.heic') ||
        lower.endsWith('.bmp');
  }

  Future<void> createCategory({
    required String name,
    required String colorStart,
    required String colorEnd,
    required int iconCodePoint,
  }) async {
    final id = 'cat_${DateTime.now().millisecondsSinceEpoch}';
    final vault = await _vaultDir;
    final catDir = Directory('${vault.path}/$id');
    await catDir.create(recursive: true);

    final category = VaultCategory(
      id: id,
      name: name,
      colorStart: colorStart,
      colorEnd: colorEnd,
      iconCodePoint: iconCodePoint,
      createdAt: DateTime.now(),
      imagePaths: [],
    );

    final metaFile = File('${catDir.path}/metadata.json');
    await metaFile.writeAsString(jsonEncode(category.toJson()));

    await loadCategories();
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required String colorStart,
    required String colorEnd,
    required int iconCodePoint,
  }) async {
    final vault = await _vaultDir;
    final catDir = Directory('${vault.path}/$id');
    if (await catDir.exists()) {
      final currentCategory = _categories.firstWhere((c) => c.id == id);
      
      final category = VaultCategory(
        id: id,
        name: name,
        colorStart: colorStart,
        colorEnd: colorEnd,
        iconCodePoint: iconCodePoint,
        createdAt: currentCategory.createdAt,
        imagePaths: currentCategory.imagePaths,
      );

      final metaFile = File('${catDir.path}/metadata.json');
      await metaFile.writeAsString(jsonEncode(category.toJson()));
      await loadCategories();
    }
  }

  Future<void> deleteCategory(String id) async {
    final vault = await _vaultDir;
    final catDir = Directory('${vault.path}/$id');
    if (await catDir.exists()) {
      await catDir.delete(recursive: true);
    }
    await loadCategories();
  }

  Future<void> addImagesToCategory(String id, List<String> paths) async {
    final vault = await _vaultDir;
    final catDir = Directory('${vault.path}/$id');
    if (!await catDir.exists()) return;

    for (final path in paths) {
      final file = File(path);
      if (await file.exists()) {
        final newFileName = 'img_${DateTime.now().microsecondsSinceEpoch}_${path.split(Platform.pathSeparator).last}';
        final sanitizedFileName = newFileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
        final targetFile = File('${catDir.path}/$sanitizedFileName');
        await file.copy(targetFile.path);
        await Future.delayed(const Duration(milliseconds: 2));
      }
    }
    await loadCategories();
  }

  Future<void> deleteImage(String id, String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
    await loadCategories();
  }

  Future<void> shareCategory(VaultCategory category) async {
    if (category.imagePaths.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(
        files: category.imagePaths.map((p) => XFile(p)).toList(),
        text: 'Shared images from category: ${category.name}',
      ),
    );
  }

  Future<bool> copyCategoryToClipboard(VaultCategory category) async {
    if (category.imagePaths.isEmpty) return false;
    return await LocalClipboard.copyFiles(category.imagePaths);
  }

  Future<bool> copyImageToClipboard(String imagePath) async {
    return await LocalClipboard.copyFiles([imagePath]);
  }

  Future<bool> sendCategoryToWhatsApp(VaultCategory category) async {
    if (category.imagePaths.isEmpty) return false;
    return await LocalClipboard.sendToWhatsApp(category.imagePaths);
  }
}
