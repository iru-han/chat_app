import 'package:oboa_chat_app/data/data_source/file_data_source.dart';
import 'package:oboa_chat_app/data/data_source/local/default_local_storage.dart';
import 'package:oboa_chat_app/data/data_source/claude_ai_data_source.dart';
import 'package:oboa_chat_app/data/data_source/google_stt_data_source.dart';
import 'package:oboa_chat_app/data/data_source/remote/supabase_file_data_source_impl.dart';
import 'package:oboa_chat_app/data/data_source/supabase_chat_data_source.dart';
import 'package:oboa_chat_app/data/data_source/supabase_chat_share_data_source.dart';
import 'package:oboa_chat_app/data/repository/chat_repository_impl.dart';
import 'package:oboa_chat_app/data/repository/chat_share_repository_impl.dart';
import 'package:oboa_chat_app/data/repository/file_repository_impl.dart';
import 'package:oboa_chat_app/data/repository/user_repository_impl.dart';
import 'package:oboa_chat_app/data/service/ai_chat_service_impl.dart';
import 'package:oboa_chat_app/data/service/clipboard_service_impl.dart';
import 'package:oboa_chat_app/data/service/file_selection_service_impl.dart';
import 'package:oboa_chat_app/data/service/share_native_service_impl.dart';
import 'package:oboa_chat_app/data/service/share_service_impl.dart';
import 'package:oboa_chat_app/data/service/speech_to_text_service_impl.dart';
import 'package:oboa_chat_app/domain/clipboard/clipboard_service.dart';
import 'package:oboa_chat_app/data/data_source/local_storage.dart';
import 'package:oboa_chat_app/domain/repository/chat_repository.dart';
import 'package:oboa_chat_app/domain/repository/chat_share_repository.dart';
import 'package:oboa_chat_app/domain/repository/file_repository.dart';
import 'package:oboa_chat_app/domain/repository/user_repository.dart';
import 'package:oboa_chat_app/domain/service/ai_service.dart';
import 'package:oboa_chat_app/domain/service/file_selection_service.dart';
import 'package:oboa_chat_app/domain/service/share_native_service.dart';
import 'package:oboa_chat_app/domain/service/share_service.dart';
import 'package:oboa_chat_app/domain/service/speech_to_text_service.dart';
import 'package:oboa_chat_app/domain/use_case/create_or_get_ai_chat_room_use_case.dart';
import 'package:oboa_chat_app/domain/use_case/get_chat_room_message_use_case.dart';
import 'package:oboa_chat_app/domain/use_case/send_chat_message_use_case.dart';
import 'package:oboa_chat_app/domain/use_case/send_chat_with_attatchments_usecase.dart';
import 'package:oboa_chat_app/domain/use_case/upload_captured_image_use_case.dart';
import 'package:oboa_chat_app/domain/use_case/upload_file_use_case.dart';
import 'package:oboa_chat_app/presentation/chat/chat_view_model.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import 'package:uuid/uuid.dart';

final getIt = GetIt.instance;

void diSetup({bool isTesting = false}) {

  getIt.registerLazySingleton<FileSelectionService>(() => FileSelectionServiceImpl());

  getIt.registerLazySingleton(() => UploadCapturedImageUseCase(fileRepository: getIt<FileRepository>()));

  // Supabase Client (make sure this is initialized once)
  if (!getIt.isRegistered<SupabaseClient>()) {
    getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  }

  // Clipboard Service
  if (!getIt.isRegistered<ClipboardService>()) {
    getIt.registerLazySingleton<ClipboardService>(() => ClipboardServiceImpl());
  }

  getIt.registerLazySingleton<ShareService>(() => ShareServiceImpl());
  // --- Chat Feature Registration ---

  // Data Sources
  getIt.registerLazySingleton<SupabaseChatDataSource>(
        () => SupabaseChatDataSource(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<ClaudeAIDataSource>(
        () => ClaudeAIDataSource(), // Claude API key handled internally by dotenv
  );
  getIt.registerLazySingleton<GoogleSTTDataSource>(
        () => GoogleSTTDataSource(),
  );
  getIt.registerLazySingleton<SupabaseShareDataSource>(
        () => SupabaseShareDataSource(getIt<SupabaseClient>()),
  );

  // Repositories
  getIt.registerLazySingleton<ChatRepository>(
        () => ChatRepositoryImpl(dataSource: getIt<SupabaseChatDataSource>()),
  );
  getIt.registerLazySingleton<ChatShareRepository>(
        () => ChatShareRepositoryImpl(dataSource: getIt<SupabaseShareDataSource>()),
  );

  // User Repository 등록
  if (!getIt.isRegistered<UserRepository>()) {
    final testUuid = const Uuid().v4(); // 고유한 테스트 사용자 ID 생성
    if (isTesting) {
      // 테스트 모드일 때 MockUserRepository 등록
      // getIt.registerLazySingleton<UserRepository>(() => MockUserRepositoryImpl(testUuid));
    } else {
      // 실제 앱 실행 시 UserRepositoryImpl 등록
      getIt.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(supabase: getIt<SupabaseClient>()));
    }
  }

  // Services
  getIt.registerLazySingleton<AIChatService>(
        () => AIChatServiceImpl(claudeAIDataSource: getIt<ClaudeAIDataSource>()),
  );
  getIt.registerLazySingleton<SpeechToTextService>(
        () => SpeechToTextServiceImpl(sttDataSource: getIt<GoogleSTTDataSource>()),
  );
  getIt.registerLazySingleton<ShareNativeService>(
      () => ShareNativeServiceImpl()
  );

  // Use Cases
  getIt.registerLazySingleton<CreateOrGetAIChatRoomUseCase>(
        () => CreateOrGetAIChatRoomUseCase(chatRepository: getIt<ChatRepository>()),
  );
  getIt.registerLazySingleton<GetChatRoomMessagesUseCase>(
        () => GetChatRoomMessagesUseCase(chatRepository: getIt<ChatRepository>()),
  );
  getIt.registerLazySingleton<SendChatMessageUseCase>(
        () => SendChatMessageUseCase(
      chatRepository: getIt<ChatRepository>(),
      aiChatService: getIt<AIChatService>(),
    ),
  );

  // --- 새로운 파일 업로드 관련 등록 ---
  getIt.registerLazySingleton<FileDataSource>(
        () => SupabaseFileDataSourceImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<FileRepository>(
        () => FileRepositoryImpl(fileDataSource: getIt<FileDataSource>()),
  );
  // getIt.registerLazySingleton<UploadFileUseCase>(
  //       () => UploadFileUseCase(fileRepository: getIt<FileRepository>()),
  // );
  // --- 파일 업로드 관련 등록 끝 ---


  getIt.registerLazySingleton<UploadFileUseCase>(
        () => UploadFileUseCase(
      fileRepository: getIt<FileRepository>(),
      chatRepository: getIt<ChatRepository>(), aiChatService: getIt<AIChatService>(), // <- ChatRepository 주입 추가
    ),
  );

  // SendChatWithAttachmentsUseCase 등록
  getIt.registerLazySingleton(() => SendChatWithAttachmentsUseCase(
    uploadFileUseCase: getIt(),
    sendChatMessageUseCase: getIt(),
  ));

  // ViewModels
  getIt.registerFactory<ChatViewModel>(
        () => ChatViewModel(
      createOrGetAIChatRoomUseCase: getIt<CreateOrGetAIChatRoomUseCase>(),
      getChatRoomMessagesUseCase: getIt<GetChatRoomMessagesUseCase>(),
      sendChatMessageUseCase: getIt<SendChatMessageUseCase>(),
      speechToTextService: getIt<SpeechToTextService>(),
      userRepository: getIt<UserRepository>(),
      clipboardService: getIt<ClipboardService>(),
      chatRepository: getIt<ChatRepository>(),
          chatShareRepository: getIt<ChatShareRepository>(),
          aiChatService: getIt<AIChatService>(),
          sendChatWithAttachmentsUseCase: getIt<SendChatWithAttachmentsUseCase>(),
          uploadCapturedImageUseCase: getIt<UploadCapturedImageUseCase>(), shareService: getIt<ShareService>(),
    ),
  );



  // data source
  getIt.registerSingleton<LocalStorage>(DefaultLocalStorage());

}
