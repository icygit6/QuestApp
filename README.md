# QuestBoard

QuestBoard is a Flutter Android app for gamified productivity: users sign in, complete RPG-style quests, earn XP, build streaks, unlock achievements, and compare progress on a leaderboard.

## Verification

```powershell
flutter pub get
flutter analyze
flutter build apk --debug
```

The debug APK is generated at `build/app/outputs/flutter-apk/app-debug.apk`.

## External API Keys

FavQs and Backendless credentials are passed via compile-time defines:

```powershell
flutter run --dart-define=FAVQS_API_KEY=YOUR_KEY `
	--dart-define=BACKENDLESS_APP_ID=YOUR_APP_ID `
	--dart-define=BACKENDLESS_REST_API_KEY=YOUR_REST_KEY `
	--dart-define=BACKENDLESS_BASE_URL=https://api.backendless.com
```
