import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/channel_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/channel_card.dart';
import '../widgets/category_chips.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/empty_state.dart';
import 'player_screen.dart';
import 'add_playlist_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildSearchBar(context),
              const SizedBox(height: 8),
              _buildCategoryChips(),
              const SizedBox(height: 12),
              _buildChannelCount(),
              const SizedBox(height: 8),
              Expanded(child: _buildChannelList(context)),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(bounds),
                child: const Text(
                  'Streamly',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Consumer<ChannelProvider>(
                builder: (context, provider, _) => Text(
                  '${provider.totalChannels} channels available',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildRefreshButton(context),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddPlaylistScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider, width: 0.5),
                  ),
                  child: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Refresh/update button that reloads channels from the saved source
  Widget _buildRefreshButton(BuildContext context) {
    return Consumer<ChannelProvider>(
      builder: (context, provider, _) => GestureDetector(
        onTap: provider.isRefreshing
            ? null
            : () async {
                await provider.refresh();
                if (context.mounted && provider.error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Updated · ${provider.totalChannels} channels'),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider, width: 0.5),
          ),
          child: provider.isRefreshing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.refresh_rounded, color: AppTheme.primary, size: 24),
        ),
      ),
    );
  }


  Widget _buildSearchBar(BuildContext context) {
    return SearchBarWidget(
      onChanged: (query) {
        context.read<ChannelProvider>().setSearchQuery(query);
      },
    );
  }

  Widget _buildCategoryChips() {
    return Consumer<ChannelProvider>(
      builder: (context, provider, _) => CategoryChips(
        categories: provider.categories,
        selectedCategory: provider.selectedCategory,
        onCategorySelected: (category) => provider.setCategory(category),
      ),
    );
  }

  Widget _buildChannelCount() {
    return Consumer<ChannelProvider>(
      builder: (context, provider, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          '${provider.channels.length} channels',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
      ),
    );
  }


  Widget _buildChannelList(BuildContext context) {
    return Consumer<ChannelProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const LoadingShimmer();

        if (provider.error != null) {
          return EmptyState(
            title: 'Something went wrong',
            subtitle: provider.error!,
            icon: Icons.error_outline_rounded,
            actionText: 'Try Again',
            onAction: () => provider.clearError(),
          );
        }

        if (provider.channels.isEmpty && provider.allChannels.isEmpty) {
          return EmptyState(
            title: 'No channels yet',
            subtitle: 'Add a playlist to get started',
            icon: Icons.playlist_add_rounded,
            actionText: 'Add Playlist',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddPlaylistScreen()),
            ),
          );
        }

        if (provider.channels.isEmpty) {
          return const EmptyState(
            title: 'No results',
            subtitle: 'Try a different search or category',
            icon: Icons.search_off_rounded,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: provider.channels.length,
          itemBuilder: (context, index) {
            final channel = provider.channels[index];
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
    );
  }
}
