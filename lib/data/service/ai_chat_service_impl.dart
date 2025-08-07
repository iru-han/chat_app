import 'dart:typed_data';

import 'package:oboa_chat_app/domain/service/ai_service.dart';
import '../data_source/claude_ai_data_source.dart';

class AIChatServiceImpl implements AIChatService {
  final ClaudeAIDataSource _claudeAIDataSource;

  AIChatServiceImpl({required ClaudeAIDataSource claudeAIDataSource})
      : _claudeAIDataSource = claudeAIDataSource;

  @override
  Future<String> getResponse(List<Map<String, dynamic>> messagesForClaude) {
    return _claudeAIDataSource.getResponse(messagesForClaude);
  }

  @override
  Future<String> uploadFileToClaude(Uint8List fileBytes, String mimeType, String fileName) {
    return _claudeAIDataSource.uploadFileToClaude(fileBytes, mimeType, fileName);
  }
}