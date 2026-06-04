import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_strings.dart';
import 'core/constants/app_theme.dart';
import 'core/providers.dart';
import 'core/routing/app_router.dart';
import 'features/gamification/data/gamification_hive_adapters.dart';
import 'features/gamification/domain/achievement.dart';
import 'features/gamification/domain/daily_record.dart';
import 'features/quests/data/quest_model.dart';
import 'features/settings/presentation/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialise Firebase for Google Sign-In. Wrapped so a missing/misconfigured
  // google-services.json degrades gracefully: the rest of QuestBoard still
  // boots and only the Google button fails (handled in GoogleAuthService).
  try {
    await Firebase.initializeApp();
  } catch (error) {
    debugPrint('Firebase initialization failed: $error');
  }

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(QuestModelAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(AchievementAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(DailyRecordAdapter());
  }
  await Hive.openBox<QuestModel>('quests');
  await Hive.openBox<QuestModel>('user_quests');
  await Hive.openBox<Achievement>('achievements');
  await Hive.openBox<DailyRecord>('daily');
  await Hive.openBox<String>('user_posts');

  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const QuestBoardApp(),
    ),
  );
}

class QuestBoardApp extends ConsumerWidget {
  const QuestBoardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      routerConfig: router,
    );
  }
}
