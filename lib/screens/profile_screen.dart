import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  bool _isUploading = false;
  File? _previewImage;

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _previewImage = File(picked.path));
    await _uploadAvatar(picked.path);
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _previewImage = File(picked.path));
    await _uploadAvatar(picked.path);
  }

  Future<void> _uploadAvatar(String filePath) async {
    setState(() => _isUploading = true);
    try {
      final response = await _apiService.postMultipart(
        ApiConfig.avatarUploadUrl,
        'avatar',
        filePath,
      );
      final data = await _apiService.handleResponse(response);

      if (data['success'] == true && data['data'] != null) {
        final avatarPath = data['data']['avatar'] as String?;
        await _storageService.saveAvatar(avatarPath);

        if (!mounted) return;
        // Refresh the auth provider so the new avatar is reflected globally
        await Provider.of<AuthProvider>(context, listen: false)
            .refreshUser();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil mise à jour !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Changer la photo de profil',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.deepPurple),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.deepPurple),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;
          if (user == null) {
            return const Center(child: Text('Non connecté'));
          }

          final avatarUrl = user.avatar != null
              ? ApiConfig.getImageUrl(user.avatar)
              : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                // Avatar
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 64,
                      backgroundColor: Colors.deepPurple.shade100,
                      backgroundImage: _previewImage != null
                          ? FileImage(_previewImage!) as ImageProvider
                          : (avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null),
                      child: (_previewImage == null &&
                              (avatarUrl == null || avatarUrl.isEmpty))
                          ? Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 48,
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    if (_isUploading)
                      const Positioned.fill(
                        child: CircleAvatar(
                          radius: 64,
                          backgroundColor: Colors.black45,
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    if (!_isUploading)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: _showPickerOptions,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                // User info
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                // Change photo button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _showPickerOptions,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Modifier la photo de profil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
