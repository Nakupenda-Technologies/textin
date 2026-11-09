import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  const Avatar({super.key, this.imageUrl, this.size = 56});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fallback = Container(
      color: cs.onSurface.withValues(alpha: 0.10),
      child: Icon(
        Icons.person,
        size: size * .45,
        color: cs.onSurface.withValues(alpha: 0.6),
      ),
    );
    final url = imageUrl?.trim();

    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: url == null || url.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    Container(color: cs.onSurface.withValues(alpha: 0.10)),
                errorWidget: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
