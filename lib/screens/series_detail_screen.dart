import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/vod_item.dart';
import '../providers/vod_provider.dart';
import '../theme/app_theme.dart';
import 'vod_player_screen.dart';

/// Series detail screen showing seasons and episodes
class SeriesDetailScreen extends StatefulWidget {
  final VodItem series;

  const SeriesDetailScreen({super.key, required this.series});

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  Map<int, List<Episode>> _episodes = {};
  bool _loading = true;
  int _selectedSeason = 1;

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
  }

  Future<void> _loadEpisodes() async {
    final provider = context.read<VodProvider>();
    final episodes = await provider.episodesOf(widget.series);
    if (mounted) {
      setState(() {
        _episodes = episodes;
        if (episodes.keys.isNotEmpty) {
          _selectedSeason = episodes.keys.reduce((a, b) => a < b ? a : b);
        }
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: AppTheme.textPrimary, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.series.name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }
    if (_episodes.isEmpty) {
      return const Center(
        child: Text('No episodes found',
            style: TextStyle(color: AppTheme.textMuted)),
      );
    }

    final seasons = _episodes.keys.toList()..sort();
    final episodes = _episodes[_selectedSeason] ?? [];

    return Column(
      children: [
        // Poster + info
        _buildPosterSection(),
        const SizedBox(height: 12),

        // Season selector
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: seasons.length,
            itemBuilder: (context, index) {
              final season = seasons[index];
              final selected = season == _selectedSeason;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedSeason = season),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: selected ? AppTheme.primaryGradient : null,
                      color: selected ? null : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Season $season',
                      style: TextStyle(
                        color: selected ? Colors.white : AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Episode list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: episodes.length,
            itemBuilder: (context, index) =>
                _buildEpisodeTile(episodes[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildPosterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 90,
            height: 130,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: widget.series.poster != null &&
                    widget.series.poster!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.series.poster!,
                    fit: BoxFit.cover,
                    errorWidget: (c, u, e) => const Icon(
                        Icons.live_tv_rounded, color: AppTheme.textMuted),
                  )
                : const Icon(Icons.live_tv_rounded, color: AppTheme.textMuted),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.series.rating != null && widget.series.rating! > 0)
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppTheme.warning, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        widget.series.rating!.toStringAsFixed(1),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                if (widget.series.genre != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      widget.series.genre!,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ),
                if (widget.series.plot != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.series.plot!,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeTile(Episode episode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.glassCard,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '${episode.episodeNum}',
            style: const TextStyle(
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          episode.title,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.play_arrow_rounded,
              color: Colors.white, size: 20),
        ),
        onTap: () async {
          final provider = context.read<VodProvider>();
          final url = await provider.episodeUrl(episode);
          if (url != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VodPlayerScreen(
                  title: '${widget.series.name} · ${episode.title}',
                  url: url,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
