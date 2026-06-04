import 'package:flutter_test/flutter_test.dart';
import 'package:questboard/features/favorites/presentation/favorites_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<FavoritesNotifier> buildNotifier([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    return FavoritesNotifier(prefs);
  }

  test('starts empty when nothing is persisted', () async {
    final notifier = await buildNotifier();
    expect(notifier.state.quoteIds, isEmpty);
    expect(notifier.state.postIds, isEmpty);
  });

  test('toggleQuote adds then removes the id', () async {
    final notifier = await buildNotifier();

    await notifier.toggleQuote(7);
    expect(notifier.state.isQuoteFavorite(7), isTrue);

    await notifier.toggleQuote(7);
    expect(notifier.state.isQuoteFavorite(7), isFalse);
  });

  test('quote and post favourites are independent', () async {
    final notifier = await buildNotifier();
    await notifier.toggleQuote(1);
    await notifier.togglePost(1);

    expect(notifier.state.isQuoteFavorite(1), isTrue);
    expect(notifier.state.isPostFavorite(1), isTrue);

    await notifier.toggleQuote(1);
    expect(notifier.state.isQuoteFavorite(1), isFalse);
    expect(notifier.state.isPostFavorite(1), isTrue);
  });

  test('favourites persist across notifier instances', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final first = FavoritesNotifier(prefs);
    await first.toggleQuote(42);
    await first.togglePost(99);

    // A fresh notifier reading the same store should see the saved ids.
    final second = FavoritesNotifier(prefs);
    expect(second.state.isQuoteFavorite(42), isTrue);
    expect(second.state.isPostFavorite(99), isTrue);
  });
}
