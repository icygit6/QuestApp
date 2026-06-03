import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/explore/presentation/explore_screen.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../../features/posts/domain/post_entity.dart';
import '../../features/posts/presentation/post_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/quotes/domain/quote_entity.dart';
import '../../features/quotes/presentation/quote_detail_screen.dart';
import '../../features/quests/domain/quest_entity.dart';
import '../../features/quests/presentation/quest_detail_screen.dart';
import '../../features/quests/presentation/quest_list_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.uri.path;
      final isPublic =
          location == '/splash' ||
          location == '/login' ||
          location == '/register';

      if (auth.status == AuthStatus.loading) {
        return location == '/splash' ? null : '/splash';
      }

      if (auth.status == AuthStatus.authenticated) {
        return isPublic ? '/quests' : null;
      }

      if (!isPublic) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/quests',
            builder: (context, state) => const QuestListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id =
                      int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                  return QuestDetailScreen(
                    questId: id,
                    initialQuest: state.extra is QuestEntity
                        ? state.extra! as QuestEntity
                        : null,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/explore',
            builder: (context, state) => const ExploreScreen(),
            routes: [
              GoRoute(
                path: 'quotes/:id',
                builder: (context, state) {
                  final id =
                      int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                  return QuoteDetailScreen(
                    quoteId: id,
                    initialQuote: state.extra is QuoteEntity
                        ? state.extra! as QuoteEntity
                        : null,
                  );
                },
              ),
              GoRoute(
                path: 'posts/:id',
                builder: (context, state) {
                  final id =
                      int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                  return PostDetailScreen(
                    postId: id,
                    initialPost: state.extra is PostEntity
                        ? state.extra! as PostEntity
                        : null,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/leaderboard',
            builder: (context, state) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
