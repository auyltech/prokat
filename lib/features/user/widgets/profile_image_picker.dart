import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImagePicker extends StatefulWidget {
  final Function(File?) onImageSelected;
  final String? initialImageUrl;

  const ProfileImagePicker({
    super.key,
    required this.onImageSelected,
    this.initialImageUrl,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndCropImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080, // Optimize for performance
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Launching the Cropper
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(
          ratioX: 1,
          ratioY: 1,
        ), // Force square for profiles
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: Colors.deepPurple,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
            resetButtonHidden: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() => _selectedImage = File(croppedFile.path));

        widget.onImageSelected(_selectedImage);
      }
    } catch (e) {
      debugPrint("User cancelled the cropper");
      debugPrint("Error picking image: $e");
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndCropImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndCropImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: GestureDetector(
        onTap: _showPickerOptions,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: theme.colorScheme.surface,
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!)
                  : (widget.initialImageUrl != null &&
                            widget
                                .initialImageUrl!
                                .isNotEmpty // Check for empty string
                        ? NetworkImage(widget.initialImageUrl!)
                        : null),
              child:
                  (_selectedImage == null &&
                      (widget.initialImageUrl == null ||
                          widget.initialImageUrl!.isEmpty))
                  ? const Icon(Icons.person, size: 60)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
