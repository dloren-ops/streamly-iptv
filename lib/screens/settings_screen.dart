import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/channel_provider.dart';
import '../providers/vod_provider.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

/// Settings screen with app configuration
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Account section
                    Consumer<ChannelProvider>(
                      builder: (context, provider, _) {
                        final account = provider.account;
                        return _buildSection('Account', [
                          _buildInfoTile(
                            icon: Icons.account_circle_outlined,
                            title: 'Username',
                            subtitle: account?.username ?? '—',
                          ),
                          _buildInfoTile(
                            icon: Icons.verified_user_outlined,
                            title: 'Status',
                            subtitle: account?.status ?? '—',
                          ),
                          if (account?.expiryDate != null)
                            _buildInfoTile(
                              icon: Icons.event_outlined,
                              title: 'Expires in',
                              subtitle: '${account!.daysRemaining ?? 0} days',
                            ),
                          _buildActionTile(
                            icon: Icons.logout_rounded,
                            title: 'Logout',
                            subtitle: 'Sign out and clear data',
                            isDestructive: true,
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppTheme.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text('Logout',
                                      style: TextStyle(color: AppTheme.textPrimary)),
                                  content: const Text(
                                    'You will be signed out and your channels removed. Continue?',
                                    style: TextStyle(color: AppTheme.textSecondary),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Logout',
                                          style: TextStyle(color: AppTheme.error)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && context.mounted) {
                                await context.read<ChannelProvider>().logout();
                                if (context.mounted) {
                                  context.read<VodProvider>().clear();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const LoginScreen()),
                                    (route) => false,
                                  );
                                }
                              }
                            },
                          ),
                        ]);
                      },
                    ),

                    const SizedBox(height: 16),

                    // App info
                    _buildSection('About', [
                      _buildInfoTile(
                        icon: Icons.info_outline_rounded,
                        title: 'Version',
                        subtitle: '1.0.0',
                      ),
                      _buildInfoTile(
                        icon: Icons.code_rounded,
                        title: 'Built with',
                        subtitle: 'Flutter + Dart',
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // Stats
                    Consumer<ChannelProvider>(
                      builder: (context, provider, _) => _buildSection('Statistics', [
                        _buildInfoTile(
                          icon: Icons.tv_rounded,
                          title: 'Total Channels',
                          subtitle: '${provider.totalChannels}',
                        ),
                        _buildInfoTile(
                          icon: Icons.favorite_rounded,
                          title: 'Favorites',
                          subtitle: '${provider.totalFavorites}',
                        ),
                        _buildInfoTile(
                          icon: Icons.category_rounded,
                          title: 'Categories',
                          subtitle: '${provider.categories.length - 1}',
                        ),
                      ]),
                    ),

                    const SizedBox(height: 16),

                    // Player settings
                    _buildSection('Player', [
                      _buildSwitchTile(
                        icon: Icons.hd_rounded,
                        title: 'Prefer HD',
                        subtitle: 'Prioritize high quality streams',
                        value: true,
                        onChanged: (val) {},
                      ),
                      _buildSwitchTile(
                        icon: Icons.picture_in_picture_rounded,
                        title: 'Background play',
                        subtitle: 'Continue audio in background',
                        value: false,
                        onChanged: (val) {},
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // Data
                    _buildSection('Data', [
                      _buildActionTile(
                        icon: Icons.refresh_rounded,
                        title: 'Refresh Playlist',
                        subtitle: 'Reload channels from source',
                        onTap: () async {
                          final provider = context.read<ChannelProvider>();
                          await provider.refresh();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  provider.error ??
                                      'Updated · ${provider.totalChannels} channels',
                                ),
                                backgroundColor: provider.error != null
                                    ? AppTheme.error
                                    : AppTheme.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      _buildActionTile(
                        icon: Icons.delete_outline_rounded,
                        title: 'Clear Cache',
                        subtitle: 'Remove cached data',
                        isDestructive: true,
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppTheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text('Clear Cache', style: TextStyle(color: AppTheme.textPrimary)),
                              content: const Text(
                                'This will remove all cached channels and saved playlists. Are you sure?',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Clear', style: TextStyle(color: AppTheme.error)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await StorageService.clearAll();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Cache cleared'),
                                  backgroundColor: AppTheme.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ]),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: AppTheme.glassCard,
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 22),
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
      trailing: Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppTheme.primary, size: 22),
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primary,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppTheme.error : AppTheme.primary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppTheme.error : AppTheme.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
      onTap: onTap,
    );
  }
}
