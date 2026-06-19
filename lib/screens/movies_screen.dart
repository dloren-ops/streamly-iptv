import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vod_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/vod_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/empty_state.dart';
import 'vod_player_screen.dart';

/// Movies (VOD) screen with a poster grid
class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VodProvider>().loadMovies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Movies',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SearchBarWidget(
                hintText: 'Search movies...',
                onChanged: (q) => context.read<VodProvider>().searchMovies(q),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildGrid()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Consumer<VodProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingMovies) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }
        if (provider.movies.isEmpty) {
          return const EmptyState(
            title: 'No movies',
            subtitle: 'No movies available on this account',
            icon: Icons.movie_outlined,
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.55,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
          ),
          itemCount: provider.movies.length,
          itemBuilder: (context, index) {
            final movie = provider.movies[index];
            return VodCard(
              item: movie,
              onTap: () async {
                final url = await provider.movieUrl(movie);
                if (url != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          VodPlayerScreen(title: movie.name, url: url),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
