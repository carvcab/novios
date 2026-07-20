import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class FirestoreImage extends StatelessWidget {
  final String path;
  final double? height;
  final double? width;
  final BoxFit fit;
  final double borderRadius;

  static final Map<String, Uint8List> _bytesCache = {};

  const FirestoreImage({
    super.key,
    required this.path,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return _buildPlaceholder(context);
    }

    if (path.startsWith('firestore://')) {
      // Return immediately if in memory cache to prevent flickering/re-rendering
      if (_bytesCache.containsKey(path)) {
        return _buildMemoryImage(context, _bytesCache[path]!);
      }

      return FutureBuilder<Uint8List?>(
        future: StorageService().loadPhoto(path),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildLoadingPlaceholder(context);
          }
          if (snap.data == null) {
            return _buildPlaceholder(context);
          }
          _bytesCache[path] = snap.data!;
          return _buildMemoryImage(context, snap.data!);
        },
      );
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      Widget image = Image.network(
        path,
        height: height,
        width: width,
        fit: fit,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return _buildLoadingPlaceholder(context);
        },
        errorBuilder: (_, __, ___) => _buildPlaceholder(context),
      );

      if (borderRadius > 0) {
        image = ClipRRect(borderRadius: BorderRadius.circular(borderRadius), child: image);
      }
      return GestureDetector(
        onTap: () => _showFullScreenImageFromUrl(context, path),
        child: image,
      );
    } else {
      final file = File(path);
      if (!file.existsSync()) {
        return _buildPlaceholder(context);
      }
      Widget image = Image.file(
        file,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildPlaceholder(context),
      );

      if (borderRadius > 0) {
        image = ClipRRect(borderRadius: BorderRadius.circular(borderRadius), child: image);
      }
      return GestureDetector(
        onTap: () => _pushImageViewer(context, Image.file(file, fit: BoxFit.contain)),
        child: image,
      );
    }
  }

  Widget _buildMemoryImage(BuildContext context, Uint8List bytes) {
    Widget img = Image.memory(
      bytes,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
    );

    if (borderRadius > 0) {
      img = ClipRRect(borderRadius: BorderRadius.circular(borderRadius), child: img);
    }

    return GestureDetector(
      onTap: () => _showFullScreenImage(context, bytes),
      child: img,
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    return Container(
      height: height ?? 200,
      width: width ?? 220,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      height: height ?? 200,
      width: width ?? 220,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(child: Opacity(opacity: 0.3, child: Icon(Icons.broken_image_rounded))),
    );
  }
}

void _showFullScreenImage(BuildContext context, Uint8List bytes) {
  _pushImageViewer(context, Image.memory(bytes, fit: BoxFit.contain));
}

void _showFullScreenImageFromUrl(BuildContext context, String path) {
  _pushImageViewer(context, Image.network(path, fit: BoxFit.contain));
}

void _pushImageViewer(BuildContext context, Widget image) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(child: image),
        ),
      ),
    ),
  );
}
