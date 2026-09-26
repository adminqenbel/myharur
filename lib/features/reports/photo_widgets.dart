import 'package:flutter/material.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/services/photo_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

/// A private photo shown through a short-lived signed URL. Shows a skeleton while signing, a quiet
/// placeholder if it can't be loaded (offline, or the post is no longer visible to this person).
class NetworkPhoto extends StatefulWidget {
  final String path;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;
  const NetworkPhoto({super.key, required this.path, this.width, this.height, this.radius = 14, this.fit = BoxFit.cover});

  @override
  State<NetworkPhoto> createState() => _NetworkPhotoState();
}

class _NetworkPhotoState extends State<NetworkPhoto> {
  late Future<String?> _url = PhotoService.urlFor(widget.path);

  @override
  void didUpdateWidget(NetworkPhoto old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) _url = PhotoService.urlFor(widget.path);
  }

  @override
  Widget build(BuildContext context) {
    Widget placeholder(Widget child) => Container(
          width: widget.width,
          height: widget.height,
          color: AppColors.fill,
          alignment: Alignment.center,
          child: child,
        );
    return ClipPath(
      clipper: ShapeBorderClipper(shape: squircle(widget.radius)),
      child: FutureBuilder<String?>(
        future: _url,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return placeholder(const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
          }
          final url = snap.data;
          if (url == null) return placeholder(const Icon(Icons.image_not_supported_outlined, color: AppColors.tertiaryLabel));
          return Image.network(
            url,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => placeholder(const Icon(Icons.broken_image_outlined, color: AppColors.tertiaryLabel)),
            loadingBuilder: (context, child, progress) => progress == null ? child : placeholder(const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        },
      ),
    );
  }
}

/// Up to three photos in a row; tap one to view it full screen.
class PhotoStrip extends StatelessWidget {
  final List<String> paths;
  final double height;
  const PhotoStrip({super.key, required this.paths, this.height = 150});

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => PhotoViewer(paths: paths, initial: i))),
          child: NetworkPhoto(path: paths[i], width: paths.length == 1 ? 260 : 190, height: height),
        ),
      ),
    );
  }
}

/// Full-screen viewer: swipe between photos, pinch to zoom.
class PhotoViewer extends StatelessWidget {
  final List<String> paths;
  final int initial;
  const PhotoViewer({super.key, required this.paths, this.initial = 0});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: PageController(initialPage: initial),
            itemCount: paths.length,
            itemBuilder: (context, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(child: NetworkPhoto(path: paths[i], radius: 0, fit: BoxFit.contain)),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                tooltip: t.closeAction,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
