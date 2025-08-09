import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projectblog/widgets/cached_network_image.dart';

class BlogImagePicker extends StatelessWidget {
  final File? mainImage;
  final String? imageUrl;
  final Function(File?) onImageSelected;
  final bool isLoading;

  const BlogImagePicker({
    super.key,
    required this.mainImage,
    required this.imageUrl,
    required this.onImageSelected,
    this.isLoading = false,
  });

  Future<void> _selectImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    
    // Use original resolution without compression for cover images
    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      // No compression parameters to maintain original quality
    );
    
    if (pickedImage != null) {
      final imageFile = File(pickedImage.path);
      // Use original image without compression for cover photos
      onImageSelected(imageFile);
    }
  
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (mainImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                mainImage!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else if (imageUrl != null && imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedImage(
                imageUrl: imageUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
              ),
            )
          else
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.image, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Select a cover image'),
              ],
            ),
          
          // Add button overlay
          if (!isLoading)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _selectImage(context),
                  splashColor: Colors.black12,
                ),
              ),
            ),
            
          // Loading indicator
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
