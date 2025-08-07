import 'package:flutter/material.dart';
import 'package:oboa_chat_app/core/di/di_setup.dart';
import 'package:oboa_chat_app/presentation/chat/chat_action.dart';
import 'package:oboa_chat_app/presentation/chat/chat_view_model.dart';
import 'package:oboa_chat_app/presentation/chat/screen/chat_screen.dart';

class ChatRoot extends StatefulWidget {
  final String? chatRoomId;

  const ChatRoot({
    super.key,
    this.chatRoomId,
  });

  @override
  State<ChatRoot> createState() => _ChatRootState();
}

class _ChatRootState extends State<ChatRoot> {
  final viewModel = getIt<ChatViewModel>();
  late final TextEditingController messageInputController;
  late final ScrollController chatListScrollController;

  @override
  void initState() {
    super.initState();
    messageInputController = TextEditingController();
    chatListScrollController = ScrollController();
    viewModel.onAction(ChatAction.loadChatRoom(widget.chatRoomId));
  }

  @override
  void dispose() {
    messageInputController.dispose();
    chatListScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<ChatViewModel>();
    viewModel.onAction(ChatAction.loadChatRoom(widget.chatRoomId));

    // ViewModel에서 controller를 제거했으므로, 여기에서 생성하여 주입
    final TextEditingController messageInputController = TextEditingController();
    final ScrollController chatListScrollController = ScrollController();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final state = viewModel.state;

        if (state.isLoading && state.messages.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // !!! 에러 메시지가 있을 때 SnackBar를 띄우는 로직 추가 !!!
        if (state.errorMessage != null) {
          // 빌드 완료 후 실행되도록 예약
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                duration: const Duration(seconds: 3), // 토스트처럼 짧은 시간
              ),
            );
            // SnackBar를 띄운 후 ViewModel에 에러 상태를 초기화하도록 요청
            viewModel.onAction(const ChatAction.clearError());
          });
        }

        return ChatScreen(
          state: state,
          onAction: viewModel.onAction,
          // MODIFIED: onTapMenu logic to use new ChatActions
          onTapMenu: (menu) {
            switch (menu) {
              case ChatMenu.share:
              // When "Share" is tapped from the AppBar menu, enter the share/capture mode.
                viewModel.onAction(const ChatAction.enterShareCaptureMode());
                break;
              case ChatMenu.capture:
              // When "Capture" is tapped from the AppBar menu, show the capture options dialog directly.
                viewModel.onAction(const ChatAction.showCaptureOptionsDialog());
                break;
            }
          },
          messageInputController: messageInputController, // <- 컨트롤러 주입
          chatListScrollController: chatListScrollController, // <- 컨트롤러 주입
          viewModel: viewModel,
        );
      },
    );
  }
}