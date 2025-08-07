import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:oboa_chat_app/domain/model/selected_attachment.dart';
import 'package:oboa_chat_app/domain/service/file_selection_service.dart';
import 'package:uuid/uuid.dart';


class FileSelectionServiceImpl implements FileSelectionService {
  final ImagePicker _imagePicker = ImagePicker();
  final FilePicker _filePicker = FilePicker.platform;
  final Uuid _uuid = const Uuid();

  @override
  Future<SelectedAttachment?> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (image == null) return null;

      final fileBytes = await image.readAsBytes();
      final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';

      // 용량 구하기 --
      // final fileSizeInBytes = fileBytes.length;
      // final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
      // print('이미지 용량: $fileSizeInBytes bytes (${fileSizeInMB.toStringAsFixed(2)} MB)');

      return SelectedAttachment(
        id: _uuid.v4(),
        path: image.path,
        name: image.name,
        type: 'image',
        bytes: fileBytes,
        previewUrl: image.path,
        mimeType: mimeType,
      );
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  @override
  Future<SelectedAttachment?> pickFile() async {
    try {
      final result = await _filePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false, // 1개만 허용
      );

      if (result == null || result.files.single.path == null) return null;

      final filePath = result.files.single.path!;
      var fileBytes = result.files.single.bytes;
      fileBytes ??= await File(filePath).readAsBytes();

      final fileName = result.files.single.name;
      final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';

      String fileType = 'file';
      if (mimeType.startsWith('image/')) {
        fileType = 'image';
      } else if (mimeType.startsWith('video/')) {
        fileType = 'video';
      } else if (mimeType.endsWith('/pdf')) {
        fileType = 'pdf';
      }

      return SelectedAttachment(
        id: _uuid.v4(),
        path: filePath,
        name: fileName,
        type: fileType,
        bytes: fileBytes,
        previewUrl: (fileType == 'image' && fileBytes != null) ? filePath : null,
        mimeType: mimeType,
      );
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }
}