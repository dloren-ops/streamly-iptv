import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/channel_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/channel_card.dart';
import '../widgets/empty_state.dart';
import 'player_screen.dart';

/// Favorites screen showing bookmarked channels
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: AppTheme.error,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Favorites',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Consumer<ChannelProvider>(
                      builder: (context, provider, _) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${provider.totalFavorites}',
                          style: const TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Favorites list
              Expanded(
                child: Consumer<ChannelProvider>(
                  builder: (context, provider, _) {
                    final favorites = provider.favorites;

                    if (favorites.isEmpty) {
                      return const EmptyState(
                        title: 'No favorites yet',
                        subtitle: 'Tap the heart icon on any channel\nto add it to your favorites',
                        icon: Icons.favorite_border_rounded,
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final channel = favorites[index];
                        return ChannelCard(
                          channel: channel,
                          nowPlaying: provider.currentProgram(channel),
                          onTap: () {
                            provider.setCurrentChannel(channel);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlayerScreen(channel: channel),
                              ),
                            );
                          },
                          onFavorite: () => provider.toggleFavorite(channel),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
