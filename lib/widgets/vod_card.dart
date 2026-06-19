import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/vod_item.dart';
import '../theme/app_theme.dart';

/// Poster card for a movie or series, used in a grid
class VodCard extends StatelessWidget {
  final VodItem item;
  final VoidCallback onTap;

  const VodCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.poster != null && item.poster!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: item.poster!,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => _placeholder(),
                      errorWidget: (c, u, e) => _placeholder(),
                    )
                  else
                    _placeholder(),

                  // Rating badge
                  if (item.rating != null && item.rating! > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppTheme.warning, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              item.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.name,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.surfaceLight,
      child: Icon(
        item.type == VodType.movie
            ? Icons.movie_rounded
            : Icons.live_tv_rounded,
        color: AppTheme.textMuted,
        size: 36,
      ),
    );
  }
}
