import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;

class ImageUtil {
  /// Compress an image file to reduce size while maintaining reasonable quality
  static Future<File?> compressImage(File file, {int quality = 80}) async {
    try {
      // Get file extension
      final fileExt = p.extension(file.path).toLowerCase();
      
      // Get temporary directory for saving compressed image
      final dir = await path_provider.getTemporaryDirectory();
      final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed$fileExt';
      
      // Compress the image
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 1000, // Reasonable width for blog images
        minHeight: 800, // Reasonable height
      );
      
      if (result != null) {
        final compressedFile = File(result.path);
        print('🖼️ Image compressed: ${file.lengthSync() ~/ 1024}KB -> ${compressedFile.lengthSync() ~/ 1024}KB');
        return compressedFile;
      }
      
      return null;
    } catch (e) {
      print('❌ Error compressing image: $e');
      return file; // Return original file if compression fails
    }
  }
  
  /// Crop an image to 16:9 aspect ratio for blog cover without using image_cropper
  static Future<File?> cropCoverImage(File imageFile) async {
    try {
      // Read the image file
      final Uint8List bytes = await imageFile.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image image = fi.image;
      
      // Calculate crop dimensions for 16:9 ratio
      final int originalWidth = image.width;
      final int originalHeight = image.height;
      
      // Current aspect ratio
      final double currentRatio = originalWidth / originalHeight;
      // Target aspect ratio (16:9 = 1.7777...)
      const double targetRatio = 16 / 9;
      
      int cropWidth, cropHeight, offsetX = 0, offsetY = 0;
      
      if (currentRatio > targetRatio) {
        // Image is wider than 16:9, need to crop width
        cropHeight = originalHeight;
        cropWidth = (originalHeight * targetRatio).round();
        offsetX = ((originalWidth - cropWidth) / 2).round();
      } else {
        // Image is taller than 16:9, need to crop height
        cropWidth = originalWidth;
        cropHeight = (originalWidth / targetRatio).round();
        offsetY = ((originalHeight - cropHeight) / 2).round();
      }
      
      // Create a recorder to capture the drawing
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      
      // Draw the cropped portion of the image
      final Rect srcRect = Rect.fromLTWH(
        offsetX.toDouble(), 
        offsetY.toDouble(), 
        cropWidth.toDouble(), 
        cropHeight.toDouble()
      );
      final Rect dstRect = Rect.fromLTWH(0, 0, cropWidth.toDouble(), cropHeight.toDouble());
      
      canvas.drawImageRect(image, srcRect, dstRect, Paint());
      
      // Convert to image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image croppedImage = await picture.toImage(cropWidth, cropHeight);
      final ByteData? byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw Exception('Failed to encode image');
      }
      
      // Save to file
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await path_provider.getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_cropped.png');
      await tempFile.writeAsBytes(pngBytes);
      
      print('✂️ Image cropped to 16:9 aspect ratio');
      
      // Compress the cropped image for better size
      return await compressImage(tempFile, quality: 90);
    } catch (e) {
      print('❌ Error cropping image: $e');
      return null;
    }
  }
}
