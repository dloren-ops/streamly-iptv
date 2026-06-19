import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../providers/channel_provider.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// Screen to add a new playlist (URL or local file)
class AddPlaylistScreen extends StatefulWidget {
  const AddPlaylistScreen({super.key});

  @override
  State<AddPlaylistScreen> createState() => _AddPlaylistScreenState();
}

class _AddPlaylistScreenState extends State<AddPlaylistScreen> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isLoading = true);

    final provider = context.read<ChannelProvider>();
    await provider.loadFromUrl(url);

    // Save playlist URL for future use
    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'My Playlist';
    await StorageService.savePlaylistUrl(name, url);

    setState(() => _isLoading = false);

    if (mounted && provider.error == null) {
      Navigator.pop(context);
      _showSuccess('Playlist loaded successfully!');
    }
  }

  Future<void> _loadFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['m3u', 'm3u8', 'txt'],
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isLoading = true);

      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      if (mounted) {
        final provider = context.read<ChannelProvider>();
        provider.loadFromContent(content);

        setState(() => _isLoading = false);

        if (provider.error == null) {
          Navigator.pop(context);
          _showSuccess('File loaded successfully!');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error loading file: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // URL Option
                      _buildSectionTitle('From URL'),
                      const SizedBox(height: 12),
                      _buildUrlSection(),

                      const SizedBox(height: 32),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Container(height: 0.5, color: AppTheme.divider)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          ),
                          Expanded(child: Container(height: 0.5, color: AppTheme.divider)),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // File Option
                      _buildSectionTitle('From File'),
                      const SizedBox(height: 12),
                      _buildFileSection(),

                      const SizedBox(height: 32),

                      // Saved Playlists
                      _buildSavedPlaylists(),
                    ],
                  ),
                ),
              ),
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
              child: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Add Playlist',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildUrlSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard,
      child: Column(
        children: [
          // Playlist name
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Playlist name (optional)',
              hintStyle: const TextStyle(color: AppTheme.textMuted),
              prefixIcon: const Icon(Icons.label_outline_rounded, color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // URL input
          TextField(
            controller: _urlController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'http://example.com/playlist.m3u',
              hintStyle: const TextStyle(color: AppTheme.textMuted),
              prefixIcon: const Icon(Icons.link_rounded, color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),

          // Load button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _loadFromUrl,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Load Playlist',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSection() {
    return GestureDetector(
      onTap: _isLoading ? null : _loadFromFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.upload_file_rounded,
                color: AppTheme.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Select M3U File',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Supports .m3u, .m3u8, .txt',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedPlaylists() {
    final playlists = StorageService.getPlaylists();
    if (playlists.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Saved Playlists'),
        const SizedBox(height: 12),
        ...playlists.entries.map((entry) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: AppTheme.glassCard,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.playlist_play_rounded, color: AppTheme.primary),
                ),
                title: Text(
                  entry.key,
                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  entry.value,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 16),
                onTap: () {
                  _urlController.text = entry.value;
                  _nameController.text = entry.key;
                  _loadFromUrl();
                },
              ),
            )),
      ],
    );
  }
}
