import 'dart:async';
import 'dart:io'; // File 클래스를 위해 import (XFile.readAsBytes() 사용 시 필요)
import 'dart:math';
import 'dart:typed_data'; // Uint8List를 위해 import
import 'package:appinio_social_share/appinio_social_share.dart';
import 'package:oboa_chat_app/core/di/di_setup.dart';
import 'package:oboa_chat_app/domain/model/selected_attachment.dart';
import 'package:oboa_chat_app/domain/repository/chat_repository.dart';
import 'package:oboa_chat_app/domain/service/ai_service.dart';
import 'package:oboa_chat_app/domain/service/file_selection_service.dart';
import 'package:oboa_chat_app/domain/service/share_native_service.dart';
import 'package:oboa_chat_app/domain/service/share_url_service.dart';
import 'package:oboa_chat_app/domain/use_case/get_chat_room_message_use_case.dart';
import 'package:intl/intl.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:mime/mime.dart';
import 'package:oboa_chat_app/domain/use_case/send_chat_with_attatchments_usecase.dart';
import 'package:flutter/material.dart';
import 'package:oboa_chat_app/data/service/speech_to_text_service_impl.dart';
import 'package:oboa_chat_app/domain/clipboard/clipboard_service.dart';
import 'package:oboa_chat_app/domain/use_case/upload_captured_image_use_case.dart';
import 'package:oboa_chat_app/domain/use_case/upload_file_use_case.dart'; // upload_file_user_case -> upload_file_use_case
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../domain/model/chat_message.dart';
import '../../domain/model/chat_room.dart';
import '../../domain/repository/user_repository.dart';
import '../../domain/use_case/create_or_get_ai_chat_room_use_case.dart';
import '../../domain/use_case/send_chat_message_use_case.dart';
import '../../domain/service/speech_to_text_service.dart';
import 'chat_action.dart';
import 'chat_state.dart';
import 'package:file_picker/file_picker.dart';

import 'package:flutter/rendering.dart'; // RenderRepaintBoundary를 위해
import 'package:permission_handler/permission_handler.dart'; // 권한 요청 (pubspec.yaml 추가)
import 'package:path_provider/path_provider.dart'; // getTemporaryDirectory를 위해
import 'package:share_plus/share_plus.dart'; // <- share_plus 임포트


class ChatViewModel with ChangeNotifier {
  final Uuid _uuid = const Uuid(); // <- UUID 인스턴스 추가 (SelectedAttachment ID 생성용)
  String? _lastCapturedImagePath; // <- 최종 캡처된 이미지 경로 저장 (공유용)
  final ShareUrlService _shareUrlService;

  // OverlayEntry를 안전하게 관리하기 위한 필드
  OverlayEntry? _currentCaptureOverlayEntry;

  final FileSelectionService _fileSelectionService;
  final CreateOrGetAIChatRoomUseCase _createOrGetAIChatRoomUseCase;
  final GetChatRoomMessagesUseCase _getChatRoomMessagesUseCase;
  final SendChatMessageUseCase _sendChatMessageUseCase;
  final SpeechToTextService _speechToTextService;
  final UserRepository _userRepository;
  final ClipboardService _clipboardService;
  final SendChatWithAttachmentsUseCase _sendChatWithAttachmentsUseCase;
  final UploadCapturedImageUseCase _uploadCapturedImageUseCase; // 필드 추가

  ChatState _state = const ChatState(); // ChatState() 대신 const ChatState() 사용
  ChatState get state => _state;

  StreamSubscription? _messagesSubscription;
  StreamSubscription? _sttTranscriptionSubscription;
  StreamSubscription? _sttListeningStateSubscription;

  final ShareNativeService _shareNativeService;

  ChatViewModel({
    required CreateOrGetAIChatRoomUseCase createOrGetAIChatRoomUseCase,
    required GetChatRoomMessagesUseCase getChatRoomMessagesUseCase,
    required SendChatMessageUseCase sendChatMessageUseCase,
    required SpeechToTextService speechToTextService,
    required UserRepository userRepository,
    required ClipboardService clipboardService,
    required ChatRepository chatRepository,
    required AIChatService aiChatService,
    required ShareNativeService shareNativeService,
    FileSelectionService? fileSelectionService,
    required SendChatWithAttachmentsUseCase sendChatWithAttachmentsUseCase,
    required UploadCapturedImageUseCase uploadCapturedImageUseCase,
    required ShareUrlService shareUrlService
  })  : _createOrGetAIChatRoomUseCase = createOrGetAIChatRoomUseCase,
        _getChatRoomMessagesUseCase = getChatRoomMessagesUseCase,
        _sendChatMessageUseCase = sendChatMessageUseCase,
        _speechToTextService = speechToTextService,
        _userRepository = userRepository,
        _clipboardService = clipboardService,
        _shareNativeService = shareNativeService,
        _fileSelectionService = fileSelectionService ?? getIt<FileSelectionService>(),
        _sendChatWithAttachmentsUseCase = sendChatWithAttachmentsUseCase,
        _uploadCapturedImageUseCase = uploadCapturedImageUseCase,
        _shareUrlService = shareUrlService
  {
    _initSpeechToTextSubscriptions();
  }

  void _initSpeechToTextSubscriptions() {
    _sttTranscriptionSubscription = _speechToTextService.transcriptionStream.listen((text) {
      print("speech text : $text"); // 인식된 음성 텍스트
      // ViewModel의 currentInputText와 TextField 컨트롤러 업데이트
      onAction(ChatAction.updateTranscription(text));
    });

    _sttListeningStateSubscription = _speechToTextService.listeningStateStream.listen((isListening) {
      _state = _state.copyWith(isListening: isListening);
      notifyListeners();
    });
  }

  void onAction(ChatAction action) async {
    switch (action) {
      case LoadChatRoom():
        try {
          // 채팅방 로딩
          _loadChatRoom(action.roomId);
        } catch (e) {
          print("error: $e");
        }
        break;

      case StartListening():
        _speechToTextService.listen();
        break;

      case StopListening():
        _speechToTextService.stopListening();
        final String finalTranscription = state.currentInputText; // ViewModel state의 최종 텍스트 사용

        if (finalTranscription.trim().isNotEmpty) {
          print('StopListening: Auto-sending message: "$finalTranscription"');
          await _sendTextMessage(finalTranscription); // 최종 텍스트 전송
        } else {
          print('StopListening: Input empty, not sending message.');
        }
        _state = _state.copyWith(isListening: false);
        notifyListeners();
        break;

      case UpdateTranscription(): // STT 스트림으로부터 텍스트가 올 때 호출
        _state = _state.copyWith(currentInputText: action.text);
        print('UpdateTranscription action.text: ${action.text}');
          final TextEditingValue newValue = TextEditingValue(
            text: action.text,
            selection: TextSelection.collapsed(offset: action.text.length),
          );
        break;

      case ShowShareDialog():
        _state = state.copyWith(showShareDialogPopup: true);
        notifyListeners();
        break;
      case HideShareDialog():
        _state = state.copyWith(showShareDialogPopup: false);
        notifyListeners();
        break;
      case EnterShareCaptureMode():
        _state = state.copyWith(
          isInShareCaptureMode: true,
          shareRangeStartMessageId: null,
          shareRangeEndMessageId: null,
        );
        notifyListeners();
        break;
      case ExitShareCaptureMode():
        _state = state.copyWith(
          isInShareCaptureMode: false,
          shareRangeStartMessageId: null,
          shareRangeEndMessageId: null,
          showShareDialogPopup: false,
          showCaptureOptionsDialogPopup: false,
        );
        notifyListeners();
        break;

      case ShowCaptureOptionsDialog():
        _state = state.copyWith(showCaptureOptionsDialogPopup: true);
        notifyListeners();
        break;
      case HideCaptureOptionsDialog():
        _state = state.copyWith(showCaptureOptionsDialogPopup: false);
        notifyListeners();
        break;

      case SetProfileMasking():
        _state = state.copyWith(maskProfile: action.value);
        notifyListeners();
        break;
      case SetBotNameMasking():
        _state = state.copyWith(maskBotName: action.value);
        notifyListeners();
        break;
      case SetBackgroundMasking():
        _state = state.copyWith(maskBackground: action.value);
        notifyListeners();
        break;
      case ConfirmCaptureOptions():
        _state = state.copyWith(showCaptureOptionsDialogPopup: false);
        notifyListeners();
        // TODO: 여기서 실제 캡쳐 로직 호출
        break;

      case CopyShareLink():
        _clipboardService.copyText(action.link);
        print('Share Link Copied: ${action.link}');
        _state = state.copyWith(showShareDialogPopup: false);
        notifyListeners();
        break;

      case SelectMessageForShare(): // 공유를 위한 메시지 선택
        final selectedId = action.messageId;
        print("selectedId :${selectedId}");
        if (state.shareRangeStartMessageId == null) {
          _state = state.copyWith(shareRangeStartMessageId: selectedId);
        } else if (state.shareRangeEndMessageId == null) {
          final startIndex = state.messages.indexWhere((msg) => msg.id == state.shareRangeStartMessageId);
          final endIndex = state.messages.indexWhere((msg) => msg.id == selectedId);
          print("startIndex :${startIndex}");
          print("endIndex :${endIndex}");
          if (startIndex != -1 && endIndex != -1 && startIndex > endIndex) {
            _state = state.copyWith(shareRangeEndMessageId: state.shareRangeStartMessageId, shareRangeStartMessageId: selectedId);
          } else {
            _state = state.copyWith(shareRangeEndMessageId: selectedId);
          }
        } else {
          _state = state.copyWith(shareRangeStartMessageId: selectedId, shareRangeEndMessageId: null);
        }
        print("state.shareRangeEndMessageId :${state.shareRangeEndMessageId}");
        print("state.shareRangeStartMessageId :${state.shareRangeStartMessageId}");
        notifyListeners();
        break;
      case ClearShareRangeSelection():
        _state = state.copyWith(
          shareRangeStartMessageId: null,
          shareRangeEndMessageId: null,
        );
        notifyListeners();
        break;
      case ConfirmShareSelection():
        print("ConfirmShareSelection() : ");
        _state = state.copyWith(isInShareCaptureMode: false);

        // 선택된 메시지들을 필터링합니다.
        final String? startMessageId = state.shareRangeStartMessageId;
        final String? endMessageId = state.shareRangeEndMessageId;
        print("startMessageId : ${startMessageId}");
        print("endMessageId : ${endMessageId}");

        if (startMessageId == null) {
          _state = state.copyWith(errorMessage: '캡처할 메시지 범위를 선택해주세요.');
          notifyListeners();
          return;
        }

        final startIndex = state.messages.indexWhere((msg) => msg.id == startMessageId);
        final endIndex = state.messages.indexWhere((msg) => msg.id == endMessageId);
        print("startIndex : ${startIndex}");
        print("endIndex : ${endIndex}");

        int effectiveStartIndex = min(startIndex, endIndex);
        int effectiveEndIndex = max(startIndex, endIndex);
        print("effectiveStartIndex : ${effectiveStartIndex}");
        print("effectiveEndIndex : ${effectiveEndIndex}");

        if (startIndex == -1) {
          _state = state.copyWith(errorMessage: '캡처할 메시지를 찾을 수 없습니다.');
          notifyListeners();
          return;
        }
        if (endMessageId == null || endIndex == -1) {
          effectiveEndIndex = startIndex; // 시작 메시지 하나만 선택된 경우
          print("effectiveEndIndex 2 : ${effectiveEndIndex}");
        }

        final List<ChatMessage> messagesToCapture = [];
        for (int i = 0; i < state.messages.length; i++) {
          if (i >= effectiveStartIndex && i <= effectiveEndIndex) {
            messagesToCapture.add(state.messages[i]);
          }
        }
        print("messagesToCapture : ${messagesToCapture}");
        // 캡처할 위젯을 동적으로 생성하여 _captureChatContent로 전달 (ChatScreen에서 생성하여 전달)
        // ChatScreen의 _buildShareCaptureButtons 메서드에서 이 호출이 이루어져야 합니다.
        // 현재는 ChatScreen의 onAction에서 호출되고 있으므로, ChatScreen에서 위젯을 만들어서 전달해야 합니다.
        // 이 부분은 ChatScreen에서 onAction(ChatAction.startCaptureForShare(messagesToCapture))와 같이 새로운 액션을 만들고,
        // ViewModel은 그 액션을 받아 _captureChatContent를 호출하는 것이 더 MVI에 맞습니다.

        // 일단, ChatScreen에서 직접 _captureChatContent를 호출하도록 변경했으므로,
        // ConfirmShareSelection 액션은 단순히 공유 모드 종료만 처리하고, 캡처는 ChatScreen의 버튼에서 직접 호출하도록 합니다.
        // 아니면, ChatScreen에서 _captureChatContent에 필요한 widgetToCapture를 직접 만들어서 이리로 전달해야 합니다.

        // **제시된 코드 기반의 최종 결정:** ChatScreen의 _buildShareCaptureButtons에서 직접 호출되므로,
        // ConfirmShareSelection에서는 캡처 로직을 호출하지 않고, 오직 상태만 변경합니다.
        // (이전 답변에서 이 부분이 이미 수정되어 있었습니다.)
        break;

      case PickImage(): // 이미지 선택 액션
        await _pickImage();
        break;
      case PickFile(): // 파일 선택 액션
        await _pickFile();
        break;
      case SendFileMessage(): // 파일/이미지 메시지 UI에 반영 (DB 저장 아님, UseCase가 이미 함)
      // 이 액션은 _uploadFileAndSendChatMessage가 UseCase 완료 후 반환된 ChatMessage를
      // ViewModel의 상태에 추가하기 위해 호출하는 내부적인 액션으로 사용됩니다.
      print("action.fileName : ${action.fileName}");
      print("action.type : ${action.type}");
      print("action.url : ${action.url}");
      print("action.fileName : ${action.fileName}");
        final fileMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // ID는 여기서 다시 생성하는 대신 UseCase에서 반환된 ID를 사용하는 것이 좋음
          roomId: state.currentChatRoom!.id, // action에 roomId가 없음. 따라서 SendFileMessage 액션 정의 변경 필요.
          senderId: state.currentUserId!, // action에 senderId 없음
          text: action.fileName ?? '', // action에 text 없음
          createdAt: DateTime.now(), // action에 createdAt 없음
          type: action.type,
          imageUrl: action.url,
          fileUrl: action.url,
          fileName: action.fileName,
        );
        _state = state.copyWith(messages: [...state.messages, fileMessage]);
        notifyListeners();
        break;
      case ShowPopupMenu():
        _state = state.copyWith(showPopupMenu: true);
        notifyListeners();
        break;
      case HidePopupMenu():
        _state = state.copyWith(showPopupMenu: false);
        notifyListeners();
        break;
      case AddSelectedAttachment(): // 선택된 파일 목록에 추가
        var attachmentList = [...state.selectedAttachments, action.attachment];
        _state = state.copyWith(selectedAttachments: attachmentList);
        notifyListeners();
        break;
      case RemoveSelectedAttachment(): // 선택된 파일 목록에서 제거
        _state = state.copyWith(
            selectedAttachments: state.selectedAttachments.where((a) => a.id != action.attachmentId).toList());
        notifyListeners();
        break;
      case SendChatMessageWithAttachments(:final text, :final attachments): // 메시지와 첨부 파일을 함께 보낼 때
        await _sendTextMessageAndAttachments(text, attachments);
        break;
      case ShareCapturedImage(): // <- 캡처된 이미지 공유 액션
        await _shareCapturedImage(action.imagePath);
        break;
    // !!! 새로 추가된 소셜 미디어 공유 액션 처리 !!!
      case ShareCapturedImageToFacebook():
        final String deepLinkUrl = 'oboa_chat_app://chat?roomId=${state.currentChatRoom?.id ?? 'default_room'}';
        await _shareImageToSpecificApp(action.imagePath, 'facebook', deepLinkUrl);
        break;
      case ShareCapturedImageToInstagram():
        final String deepLinkUrl = 'oboa_chat_app://chat?roomId=${state.currentChatRoom?.id ?? 'default_room'}';
        await _shareImageToSpecificApp(action.imagePath, 'instagram', deepLinkUrl);
        break;
      case ShareCapturedImageToX():
        final String deepLinkUrl = 'oboa_chat_app://chat?roomId=${state.currentChatRoom?.id ?? 'default_room'}';
        await _shareImageToSpecificApp(action.imagePath, 'twitter', deepLinkUrl);
        break;
      case ShareCapturedImageToKakaoTalk():
        final String deepLinkUrl = 'oboa_chat_app://chat?roomId=${state.currentChatRoom?.id ?? 'default_room'}';
        await _shareImageToSpecificApp(action.imagePath, 'kakaotalk', deepLinkUrl);
        break;

      case ShareFile(): // 일반 파일 공유 (Share.shareXFiles)
        await _shareFile(action.filePath, text: action.text, subject: action.subject);
        break;
      case ClearError(): // <- 이 케이스 추가
        _state = state.copyWith(errorMessage: null);
        notifyListeners();
        break;    // !!! 새로 추가된 액션 핸들러 !!!
      case SetTempImagePath(:final path):
        _state = state.copyWith(tempImagePath: path);
        notifyListeners();
        break;
      case ClearTempImagePath():
        _state = state.copyWith(tempImagePath: null);
        notifyListeners();
        break;
      case HandleCapturedImage(:final bytes):
        if (bytes != null) {
          _handleCapturedImage(bytes);
        }
        break;
      case ResetScrollState():
        _handleResetScrollState();
        break;
      case SetSupabaseImageUrl(:final url):
        _state = state.copyWith(supabaseImageUrl: url);
        notifyListeners();
        break;

      case GenerateShareUrl(:final imageUrl, :final deepLink):
        if (imageUrl != null) {
          const baseFunctionUrl = 'https://pijmzpbtyhazxmrktqrm.supabase.co/functions/v1/bright-processor';
          final twitterUrl = _shareUrlService.generateTwitterUrl(
            baseFunctionUrl: baseFunctionUrl,
            roomId: state.currentChatRoom?.id ?? '',
            imageUrl: imageUrl,
            title: 'OBOA AI Chat',
            description: 'AI 친구 OBOA와 대화해보세요!',
          );
          _state = state.copyWith(shareUrl: twitterUrl);
          notifyListeners();
        }
        break;

      case ShareToTwitter(:final url):
        _launchURL(url);
        break;
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      print('Could not launch $url');
    }
  }

  void _loadChatRoom(String? roomId) async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      // 현재 유저 가져오기
      final currentUser = await _userRepository.getCurrentUser();
      print("currentUser : $currentUser");

      // 로그인 안 되어있을 때
      if (currentUser == null) {
        _state = _state.copyWith(errorMessage: 'User not logged in.', isLoading: false);
        notifyListeners();
        return;
      }

      _state = _state.copyWith(currentUserId: currentUser.id);

      // 방 생성하거나 가져오기
      ChatRoom room = await _createOrGetAIChatRoomUseCase.execute(currentUser.id);
      _state = _state.copyWith(currentChatRoom: room);

      // 채팅 메시지 불러오기
      _messagesSubscription?.cancel();
      _messagesSubscription = _getChatRoomMessagesUseCase.execute(room.id).listen(
            (messages) async {
          _state = _state.copyWith(
              messages: messages,
              isNewMessageAdded: true
          );

          // 메시지 없을 경우 AI 메시지 생성
          if (messages.isEmpty) {
            await _sendInitialAIMessage(room.id, currentUser.id);
          }

          notifyListeners();
        },
        onError: (error) {
          _state = _state.copyWith(errorMessage: 'Failed to load messages: $error');
          notifyListeners();
        },
      );
    } catch (e) {
      _state = _state.copyWith(errorMessage: 'Failed to load chat room: $e', isLoading: false);
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  // --- 텍스트 메시지 전송 로직 (새로운 메서드) ---
  Future<void> _sendTextMessage(String text) async {
    if (text.trim().isEmpty || state.currentChatRoom == null || state.currentUserId == null) {
      return;
    }

    // 1. 사용자 메시지 생성 및 UI에 즉시 반영
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      roomId: state.currentChatRoom!.id,
      senderId: state.currentUserId!,
      text: text,
      createdAt: DateTime.now(),
      type: 'text',
    );
    _state = state.copyWith(messages: [...state.messages, userMessage]);
    notifyListeners();

    try {
      // 2. SendChatMessageUseCase 호출 (사용자 메시지 DB 저장 및 AI 응답 처리)
      // UseCase는 사용자 메시지 텍스트와 현재까지의 전체 메시지 목록(문맥 유지용)을 전달합니다.
      final aiMessage = await _sendChatMessageUseCase.execute(
        state.currentChatRoom!.id,
        state.currentUserId!,
        text, // 사용자가 보낸 텍스트
        state.messages, // <- 방금 추가된 사용자 메시지까지 포함된 현재 메시지 목록
      );

      // 3. UseCase로부터 반환된 AI 메시지를 UI에 반영
      _state = state.copyWith(messages: [...state.messages, aiMessage]);
      notifyListeners();
    } catch (e) {
      _state = state.copyWith(errorMessage: 'Failed to send message: $e');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _sttTranscriptionSubscription?.cancel();
    _sttListeningStateSubscription?.cancel();
    _speechToTextService.stopListening();
    if (_speechToTextService is SpeechToTextServiceImpl) {
      (_speechToTextService).dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // 이미 첨부 파일이 있다면 선택 로직을 실행하지 않음
      if (state.selectedAttachments.isNotEmpty) {
        _state = state.copyWith(errorMessage: '파일은 한 개만 첨부할 수 있습니다.');
        notifyListeners();
        return;
      }

      // FileSelectionService를 호출하여 이미지 파일을 선택
      final selectedAttachment = await _fileSelectionService.pickImage();
      if (selectedAttachment != null) {
        onAction(ChatAction.addSelectedAttachment(selectedAttachment));
      }
    } catch (e) {
      _state = state.copyWith(errorMessage: '이미지 선택 실패: $e');
      notifyListeners();
    }
  }

  Future<void> _pickFile() async {
    // 이미 첨부 파일이 있다면 선택 로직을 실행하지 않음
    if (state.selectedAttachments.isNotEmpty) {
      _state = state.copyWith(errorMessage: '파일은 한 개만 첨부할 수 있습니다.');
      notifyListeners();
      return;
    }

    try {
      // FileSelectionService를 호출하여 일반 파일을 선택
      final selectedAttachment = await _fileSelectionService.pickFile();
      if (selectedAttachment != null) {
        onAction(ChatAction.addSelectedAttachment(selectedAttachment));
      }
    } catch (e) {
      _state = state.copyWith(errorMessage: '파일 선택 실패: $e');
      notifyListeners();
    }
  }

  // --- 메시지와 첨부 파일 함께 전송하는 새로운 메서드 ---
  Future<void> _sendTextMessageAndAttachments(String text, List<SelectedAttachment> attachments) async {
    if (text.trim().isEmpty && attachments.isEmpty) {
      return;
    }

    _state = state.copyWith(isLoading: true);
    notifyListeners();

    print("attachments : ${attachments}");
    print("text : ${text}");

    try {
      // Use Case를 호출하고 Stream으로 반환되는 메시지를 처리
      _sendChatWithAttachmentsUseCase.execute(
        roomId: state.currentChatRoom!.id,
        userId: state.currentUserId!,
        text: text,
        attachments: attachments,
        currentMessages: state.messages,
      ).listen((message) {
        // 스트림으로 들어오는 메시지(파일/AI 응답)를 상태에 추가
        _state = state.copyWith(messages: [...state.messages, message], isNewMessageAdded: true);
      }, onDone: () {
        // 모든 메시지가 처리된 후 로딩 상태 해제 및 첨부파일 목록 초기화
        _state = state.copyWith(isLoading: false, selectedAttachments: []);
        notifyListeners();
      }, onError: (e) {
        _state = state.copyWith(errorMessage: '메시지 전송 실패: $e', isLoading: false);
        notifyListeners();
      });

    } catch (e) {
      _state = state.copyWith(errorMessage: '메시지 전송 실패: $e', isLoading: false);
      notifyListeners();
    }
  }

  // --- 캡처된 이미지를 특정 앱으로 공유하는 로직 (수정) ---
  // 이제 이 메서드는 _captureCurrentScreen으로부터 받은 경로를 사용합니다.
  // 이 메서드는 ShareCapturedImageToX/Instagram 등 액션에 연결됩니다.
  Future<void> _shareImageToSpecificApp(String imagePath, String appName, String? deepLinkUrl) async {
    _state = state.copyWith(isLoading: true);
    notifyListeners();

    String commonText = 'OBOA AI 채팅 캡처: ${DateFormat('yyyy년 M월 d일 a h:mm', 'ko_KR').format(DateTime.now())}'; // 공유 텍스트
    bool sharedSuccessfully = false;
    String finalErrorMessage = '';

    try {
      final XFile imageFile = XFile(imagePath);
      final Uri encodedImageUri = Uri.file(imagePath);

      switch (appName) {
        case 'instagram':
          final Uri? instagramStoriesUri = Uri.tryParse('instagram-stories://share?source_application=YOUR_APP_ID&content_url=${encodedImageUri.toString()}&sticker_asset_id=YOUR_STICKER_ASSET_ID'); // YOUR_APP_ID 필요

          if (instagramStoriesUri != null && await canLaunchUrl(instagramStoriesUri)) {
            await launchUrl(instagramStoriesUri, mode: LaunchMode.externalApplication);
            sharedSuccessfully = true;
          } else {
            print('인스타그램 스토리 직접 공유 실패. 기본 공유 시트 사용.');
          }
          break;

        case 'twitter': // For X App
          final String tweetText = Uri.encodeComponent(commonText);
          final Uri tweetUri = Uri.parse('twitter://post?message=$tweetText');
          if (await canLaunchUrl(tweetUri)) {
            await launchUrl(tweetUri, mode: LaunchMode.externalApplication);
            sharedSuccessfully = true;
          } else {
            print('X 앱을 찾을 수 없거나 직접 공유가 지원되지 않습니다. 기본 공유 시트 사용.');
          }
          break;

        case 'kakaotalk':
          try {
            final FeedTemplate feedTemplate = FeedTemplate(
              content: Content(
                title: 'OBOA AI 채팅 캡처',
                description: commonText,
                imageUrl: encodedImageUri, // 로컬 이미지 경로를 URL로 사용
                link: Link(
                  webUrl: Uri.parse('https://oboa.ai/chat'),
                  mobileWebUrl: Uri.parse('https://oboa.ai/chat'),
                  androidExecutionParams: {'roomId': state.currentChatRoom?.id ?? ''},
                  iosExecutionParams: {'roomId': state.currentChatRoom?.id ?? ''},
                ),
              ),
              buttons: [
                Button(
                  title: '앱에서 보기',
                  link: Link(
                    androidExecutionParams: {'roomId': state.currentChatRoom?.id ?? ''},
                    iosExecutionParams: {'roomId': state.currentChatRoom?.id ?? ''},
                    webUrl: Uri.parse('https://oboa.ai/chat'),
                    mobileWebUrl: Uri.parse('https://oboa.ai/chat'),
                  ),
                ),
              ],
            );
            final Uri uri = await ShareClient.instance.shareDefault(template: feedTemplate);
            await launchUrl(uri);
            sharedSuccessfully = true;
          } catch (e) {
            print('카카오톡 공유 실패: $e. 기본 공유 시트를 사용합니다.');
          }
          break;
        case 'facebook':
          String appId = "2136875417065704";
          print('DEBUG: Attempting native Facebook share via platform channel.');
          // 플랫폼 채널을 통해 네이티브 Facebook 공유 메서드 호출
          // imagePath, commonText, 그리고 deepLinkUrl을 전달합니다.

          String shareText = "";
          shareText = await _shareNativeService.shareImageToFacebook(deepLinkUrl!);
          print("shareText :${shareText}");
          print("deepLinkUrl :${deepLinkUrl}");

          if (shareText == "Success from Android") {
            sharedSuccessfully = true;
            _state = state.copyWith(errorMessage: '페이스북으로 공유 완료');
          } else {
            finalErrorMessage = '페이스북 앱을 찾을 수 없거나 직접 공유가 지원되지 않습니다.';
          }
          break;
        default:
        // 기존 폴백 로직
          final Uri? appUri = Uri.tryParse('$appName://');
          if (appUri != null && await canLaunchUrl(appUri)) {
            await launchUrl(appUri, mode: LaunchMode.externalApplication);
            sharedSuccessfully = true;
            _state = state.copyWith(errorMessage: '$appName 앱 열기 시도');
          } else {
            finalErrorMessage = '$appName 앱을 찾을 수 없거나 직접 공유가 지원되지 않습니다. 기본 공유 시트를 사용합니다.';
          }
          break;
      }

      if (sharedSuccessfully) {
        _state = state.copyWith(errorMessage: '$appName으로 공유 완료');
      } else {
        print('Warning: Direct sharing to $appName failed or not supported. Falling back to generic share sheet.');
        await SharePlus.instance.share(
          ShareParams(
            files: [imageFile],
            text: commonText,
            subject: 'OBOA AI 채팅 캡처',
          ),
        );
        _state = state.copyWith(errorMessage: '기본 공유 시트 사용 ($appName)');
      }

    } catch (e) {
      print('Error in _shareImageToSpecificApp for $appName: $e');
      _state = state.copyWith(errorMessage: '공유 중 오류 발생: $e');
    } finally {
      _state = state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<void> _shareCapturedImage(String imagePath) async {
    _state = state.copyWith(isLoading: true);
    notifyListeners();
    try {
      final XFile imageFile = XFile(imagePath);
      await Share.shareXFiles([imageFile], text: '내가 채팅 화면을 공유합니다!');
      _state = state.copyWith(errorMessage: '이미지 공유 완료');
    } catch (e) {
      print('Error sharing image: $e');
      _state = state.copyWith(errorMessage: '이미지 공유 실패: $e');
    } finally {
      _state = state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  // --- ShareFile 액션 처리 로직 (수정) ---
  Future<void> _shareFile(String filePath, {String? text, String? subject}) async {
    _state = state.copyWith(isLoading: true);
    notifyListeners();
    try {
      final String? mime = lookupMimeType(filePath);
      final XFile file = XFile(filePath, mimeType: mime); // XFile에 mimeType 지정

      final params = ShareParams(
        text: text,
        subject: subject,
        files: [file], // XFile 리스트 전달
      );

      final result = await SharePlus.instance.share(params); // <- 변경된 API 사용

      if (result.status == ShareResultStatus.success) {
        _state = state.copyWith(errorMessage: '파일 공유 완료');
        print('SharePlus success: ${result.raw}');
      } else if (result.status == ShareResultStatus.dismissed) {
        _state = state.copyWith(errorMessage: '파일 공유 취소됨');
        print('SharePlus dismissed: ${result.raw}');
      } else if (result.status == ShareResultStatus.unavailable) {
        _state = state.copyWith(errorMessage: '공유 기능 사용 불가');
        print('SharePlus unavailable: ${result.raw}');
      }

    } catch (e) {
      print('Error sharing file: $e');
      _state = state.copyWith(errorMessage: '파일 공유 실패: $e');
    } finally {
      _state = state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<void> _sendInitialAIMessage(String roomId, String userId) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      // 1. AI에게 보낼 초기 메시지 정의
      // 이 메시지는 UI에 표시되지 않고, Claude에게 "네가 먼저 대화를 시작해줘"와 같은 지시를 내립니다.
      // 혹은 직접 Claude가 보낼 메시지를 UseCase에 하드코딩할 수도 있습니다.
      // 여기서는 Claude에게 'initial_prompt'라는 시스템 메시지를 보냈다고 가정합니다.
      const String initialPrompt = "사용자에게 먼저 인사하고, 이름이 무엇인지 물어봐줘. (이름은 나중에 변경 가능하다고 덧붙여줘)";

      // 2. Claude API에 요청을 보내고 응답을 받음
      // _aiChatService.getResponse()는 텍스트만 처리하는 방식으로 가정.
      // UseCase를 통해 처리하는 것이 MVI 원칙에 더 잘 맞습니다.
      // 여기서는 `SendChatMessageUseCase`를 재활용하거나, 별도의 UseCase를 만들 수 있습니다.
      // 편의상 `SendChatMessageUseCase`의 시그니처를 변경하여 `userMessageText`가 없을 때도 동작하도록 수정하거나,
      // 새로운 UseCase를 만드는 것이 좋습니다.

      // 일단 기존 UseCase를 활용하는 방식으로 진행
      final aiMessage = await _sendChatMessageUseCase.execute(
        roomId,
        'system', // 시스템 메시지로 전송 (사용자가 보낸 메시지가 아니므로)
        initialPrompt,
        [], // 기존 대화 기록이 없으므로 빈 리스트 전달
      );

      // 3. 받은 AI 응답을 UI에 반영
      // `_messagesSubscription`이 AI 응답을 DB에서 읽어오므로 별도의 `_state` 업데이트가 필요 없습니다.
      // `sendMessage` 메서드가 DB에 AI 메시지를 저장하면, `_messagesSubscription`이 변경을 감지하고 자동으로 UI를 업데이트합니다.

      print("Initial AI message sent to DB: ${aiMessage.text}");
    } catch (e) {
      print('Error sending initial AI message: $e');
      _state = _state.copyWith(errorMessage: 'AI 초기 메시지 전송 실패: $e');
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<void> _handleResetScrollState() async {
    _state = _state.copyWith(isNewMessageAdded: false);
    notifyListeners();
  }

  Future<void> _handleCapturedImage(Uint8List pngBytes) async {
    _state = state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final String? supabaseImageUrl = await _uploadCapturedImageUseCase.execute(pngBytes);
      onAction(ChatAction.setSupabaseImageUrl(supabaseImageUrl));
      onAction(ChatAction.generateShareUrl(supabaseImageUrl, 'your_deep_link_here')); // 딥링크 설정
      // final String? tempImagePath = await _uploadCapturedImageUseCase.execute(pngBytes);
      // if (tempImagePath != null) {
      //   onAction(ChatAction.setTempImagePath(tempImagePath));
      // } else {
      //   _state = state.copyWith(errorMessage: '이미지 저장/업로드 실패.');
      // }
    } catch (e) {
      _state = state.copyWith(errorMessage: '이미지 저장/업로드 실패: $e');
      notifyListeners();
    } finally {
      _state = state.copyWith(isLoading: false);
      notifyListeners();
    }
  }
}