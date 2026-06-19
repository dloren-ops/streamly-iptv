import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vod_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/vod_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/empty_state.dart';
import 'series_detail_screen.dart';

/// Series (VOD) screen with a poster grid
class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VodProvider>().loadSeries();
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
                  'Series',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SearchBarWidget(
                hintText: 'Search series...',
                onChanged: (q) => context.read<VodProvider>().searchSeries(q),
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
        if (provider.isLoadingSeries) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }
        if (provider.series.isEmpty) {
          return const EmptyState(
            title: 'No series',
            subtitle: 'No series available on this account',
            icon: Icons.live_tv_outlined,
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
          itemCount: provider.series.length,
          itemBuilder: (context, index) {
            final series = provider.series[index];
            return VodCard(
              item: series,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SeriesDetailScreen(series: series),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
