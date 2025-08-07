import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_parser/http_parser.dart'; // For API key

class ClaudeAIDataSource {
  final String _apiKey;
  final String _claudeApiUrl = 'https://api.anthropic.com/v1/messages'; // Or specific endpoint
  final String _claudeFilesApiUrl = 'https://api.anthropic.com/v1/files'; // <- Files API 엔드포인트

  ClaudeAIDataSource() : _apiKey = dotenv.env['CLAUDE_API_KEY'] ?? 'YOUR_CLAUDE_API_KEY';

  // --- 1. Anthropic Files API에 파일 업로드 ---
  // publicUrl은 Supabase용, 여기서는 실제 파일 바이트와 타입으로 업로드
  Future<String> uploadFileToClaude(Uint8List fileBytes, String mimeType, String fileName) async {
    if (_apiKey == 'YOUR_CLAUDE_API_KEY_NOT_SET' || _apiKey.isEmpty) {
      throw Exception('Claude API key not found.');
    }

    print("uploadFileToClaude mimeType : ${mimeType}");
    print("uploadFileToClaude fileName : ${fileName}");

    // Dio 패키지를 사용하면 MultipartFile 업로드가 더 간편합니다.
    // 여기서는 http 패키지로 Multipart Request를 직접 구성합니다.
    final request = http.MultipartRequest('POST', Uri.parse(_claudeFilesApiUrl))
      ..headers['x-api-key'] = _apiKey
      ..headers['anthropic-version'] = '2023-06-01'
      ..headers['anthropic-beta'] = 'files-api-2025-04-14' // <- 베타 기능 헤더 필수
      ..files.add(http.MultipartFile.fromBytes(
        'file', // 필드 이름이 'file'이어야 함
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType), // 'package:http_parser/http_parser.dart' 임포트 필요
      ));

    print('[CLAUDE_API_DEBUG] Uploading file to Claude Files API...');
    try {
      final streamedResponse = await request.send();
      print("uploadFileToClaude streamedResponse : ${streamedResponse}");
      final response = await http.Response.fromStream(streamedResponse);
      print("uploadFileToClaude response : ${response}");

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print('[CLAUDE_API_DEBUG] Claude File Upload Success: $data');
        return data['id']; // 업로드된 파일의 file_id 반환
      } else {
        print('[CLAUDE_API_ERROR] Claude File Upload Failed: Status Code ${response.statusCode}, Body: ${response.body}');
        throw Exception('Claude File Upload Failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[CLAUDE_API_ERROR] Error during Claude File Upload: $e');
      rethrow;
    }
  }
  Future<String> getResponse(
      List<Map<String, dynamic>> messagesForClaude, // <- 완전히 구성된 messages 배열을 직접 받음
      ) async {
    print("getResponse _apiKey : $_apiKey");
    if (_apiKey == 'YOUR_CLAUDE_API_KEY_NOT_NOT_SET' || _apiKey.isEmpty) { // 'YOUR_CLAUDE_API_KEY_NOT_SET' 오타 수정
      print('[CLAUDE_API_ERROR] Claude API Key is not set or empty. Check your .env file and main.dart dotenv.load().');
      throw Exception('Claude API key not found. Please set CLAUDE_API_KEY in .env file.');
    }

    print('[CLAUDE_API_DEBUG] Final messages to Claude API: $messagesForClaude'); // 최종 메시지 구조 로그
    print('[CLAUDE_API_DEBUG] Using API Key (first 5 chars): ${_apiKey.substring(0, 5)}...');

    try {
      final response = await http.post(
        Uri.parse(_claudeApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
          'anthropic-beta': 'files-api-2025-04-14',
        },
        body: jsonEncode({
          'model': 'claude-3-haiku-20240307',
          'max_tokens': 1024,
          'messages': messagesForClaude, // <- 직접 받은 구성된 메시지 배열 사용
        }),
      );

      print("getResponse response : $response"); // http.Response 객체 자체 로깅

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['content'] != null && data['content'].isNotEmpty) {
          return data['content'][0]['text'];
        }
        print('[CLAUDE_API_WARN] Claude API returned 200 but no content: ${response.body}');
        return 'AI 응답 내용이 없습니다.';
      } else {
        print('[CLAUDE_API_ERROR] Failed to get Claude response: Status Code ${response.statusCode}');
        print('[CLAUDE_API_ERROR] Response Body: ${response.body}');
        throw Exception('Failed to get Claude response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[CLAUDE_API_ERROR] Error calling Claude API: $e');
      return 'AI 응답을 가져오는 데 실패했습니다. (${e.toString()})';
    }
  }

  // Future<String> getResponse(
  //     String userMessageText, // 현재 사용자 입력 텍스트만 받음
  //     List<Map<String, dynamic>> chatHistoryForClaudeContext, // AI 응답에 필요한 과거 대화 기록 전체 (텍스트만, UseCase에서 이미 필터링)
  //     List<Map<String, String>>? claudeFileReferences, // <- file_id와 type (image/document) 리스트
  // ) async {
  //   // API 키가 제대로 로드되었는지 확인
  //   print("getResponse _apiKey : ${_apiKey}");
  //   if (_apiKey == 'YOUR_CLAUDE_API_KEY_NOT_SET' || _apiKey.isEmpty) {
  //     print('[CLAUDE_API_ERROR] Claude API Key is not set or empty. Check your .env file and main.dart dotenv.load().');
  //     throw Exception('Claude API key not found. Please set CLAUDE_API_KEY in .env file.');
  //   }
  //
  //   final List<Map<String, dynamic>> messagesForClaude = [];
  //
  //   var headers = {
  //     'Content-Type': 'application/json',
  //     'x-api-key': _apiKey,
  //     'anthropic-version': '2023-06-01', // Anthropic API 버전 (필수)
  //   };
  //
  //   if (claudeFileReferences == null) {
  //     for (final historyItem in chatHistoryForClaudeContext) {
  //       messagesForClaude.add({
  //         'role': historyItem['role'],
  //         'content': historyItem['content'],
  //       });
  //     }
  //     // messages = chatHistory.map((msg) => {
  //     //   'role': msg['role'], // 'user' 또는 'assistant'
  //     //   'content': msg['content'],
  //     // }).toList();
  //   } else {
  //     // chatHistory를 Messages API의 content 블록 형식에 맞게 변환
  //     // 각 메시지는 content 필드에 List<Map<String, String>> 형태의 블록을 가집니다.
  //     for (final historyItem in chatHistoryForClaudeContext) {
  //       messagesForClaude.add({
  //         'role': historyItem['role'],
  //         'content': [
  //           {'type': 'text', 'text': historyItem['content']}
  //         ],
  //       });
  //     }
  //
  //     // 현재 사용자 요청 메시지와 첨부된 파일을 content 블록으로 구성
  //     final List<Map<String, dynamic>> currentUserContent = [];
  //     currentUserContent.add({'type': 'text', 'text': userMessageText}); // 사용자 텍스트 메시지
  //
  //     for (final fileRef in claudeFileReferences) {
  //       if (fileRef['type'] == 'image') {
  //         currentUserContent.add({
  //           'type': 'image', // 또는 'document'
  //           'source': {
  //             'type': 'file',
  //             'file_id': fileRef['file_id'], // <- 업로드된 file_id 참조
  //           },
  //         });
  //       } else if (fileRef['type'] == 'pdf' || fileRef['type'] == 'document') {
  //         currentUserContent.add({
  //           'type': 'document',
  //           'source': {
  //             'type': 'file',
  //             'file_id': fileRef['file_id'],
  //           },
  //         });
  //       }
  //       // 다른 파일 유형에 대한 처리 (예: 코드 실행 도구용)
  //     }
  //
  //     // 최종 messages 배열에 사용자 메시지 추가
  //     messagesForClaude.add({
  //       'role': 'user',
  //       'content': currentUserContent, // 텍스트와 파일 참조를 포함한 content 배열
  //     });
  //
  //     headers['anthropic-beta'] = 'files-api-2025-04-14';
  //   }
  //   print("getResponse messagesForClaude : ${messagesForClaude}");
  //
  //   // Claude API는 최소 하나의 메시지를 요구하며, 사용자와 어시스턴트 역할이 번갈아 나타나야 합니다.
  //   if (messagesForClaude.isEmpty) {
  //     return 'Claude에게 전달할 채팅 기록이 없습니다.';
  //   }
  //   // Claude API는 'user' 역할로 시작해야 합니다.
  //   // 만약 마지막 메시지가 'assistant'이고 사용자의 새 메시지가 없는 경우 추가적인 로직이 필요할 수 있습니다.
  //   // 현재는 사용자가 메시지를 보낼 때 호출되므로 첫 메시지는 'user'가 될 것입니다.
  //
  //   try {
  //     print('[CLAUDE_API_DEBUG] Calling Claude API with messagesForClaude: $messagesForClaude'); // 전송될 메시지 로그
  //     print('[CLAUDE_API_DEBUG] Using API Key (first 5 chars): ${_apiKey.substring(0, 5)}...'); // 보안상 키 일부만 로그
  //
  //     final response = await http.post(
  //       Uri.parse(_claudeApiUrl),
  //       headers: headers,
  //       body: jsonEncode({
  //         'model': 'claude-3-haiku-20240307', // 사용하려는 Claude 3 모델 (opus, sonnet, haiku 중 선택)
  //         'max_tokens': 1024, // AI 응답의 최대 토큰 수
  //         'messages': messagesForClaude,
  //       }),
  //     );
  //     print("getResponse response : ${response}");
  //
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(utf8.decode(response.bodyBytes));
  //       if (data['content'] != null && data['content'].isNotEmpty) {
  //         return data['content'][0]['text'];
  //       }
  //       print('[CLAUDE_API_WARN] Claude API returned 200 but no content: ${response.body}');
  //       return 'AI 응답 내용이 없습니다.';
  //     } else {
  //       // HTTP 상태 코드가 200이 아닐 때 상세 에러 로그 출력
  //       print('[CLAUDE_API_ERROR] Failed to get Claude response: Status Code ${response.statusCode}');
  //       print('[CLAUDE_API_ERROR] Response Body: ${response.body}');
  //       throw Exception('Failed to get Claude response: ${response.statusCode} - ${response.body}');
  //     }
  //   } catch (e) {
  //     // 그 외 네트워크 에러, JSON 파싱 에러 등 일반 예외 처리
  //     print('[CLAUDE_API_ERROR] Error calling Claude API: $e');
  //     return 'AI 응답을 가져오는 데 실패했습니다. (${e.toString()})'; // 예외 내용을 포함하여 반환
  //   }
  // }
}