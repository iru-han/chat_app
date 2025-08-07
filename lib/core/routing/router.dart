import 'package:oboa_chat_app/core/routing/route_paths.dart';
import 'package:oboa_chat_app/presentation/chat/screen/chat_root.dart';
import 'package:go_router/go_router.dart';

// GoRouter configuration
final router = GoRouter(
  initialLocation: RoutePaths.chat,
  routes: [
    GoRoute(
      path: RoutePaths.chat,
      builder: (context, state) => const ChatRoot(),
    ),
  ],
);
