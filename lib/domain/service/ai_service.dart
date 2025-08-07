import 'dart:typed_data';

abstract interface class AIChatService {
  // Future<String> getClaudeResponse(List<Map<String, dynamic>> chatHistory);
  Future<String> getResponse(List<Map<String, dynamic>> messagesForClaude);

  Future<String> uploadFileToClaude(Uint8List fileBytes, String mimeType, String fileName);
}