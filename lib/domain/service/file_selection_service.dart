import 'package:oboa_chat_app/domain/model/selected_attachment.dart';

abstract class FileSelectionService {
  Future<SelectedAttachment?> pickImage();
  Future<SelectedAttachment?> pickFile();
}