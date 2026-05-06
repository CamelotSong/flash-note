import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/record/presentation/screens/record_screen.dart';
import '../../features/detail/presentation/screens/note_detail_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';
import '../../features/ai_chat/presentation/screens/ai_chat_screen.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (state.uri.toString().contains('quick_record')) {
        return '/record';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/record', builder: (_, __) => const RecordScreen()),
      GoRoute(
        path: '/note/:id',
        builder: (_, state) =>
            NoteDetailScreen(noteId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
      GoRoute(path: '/ai-chat', builder: (_, __) => const AiChatScreen()),
    ],
  );
}
