import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers.dart';

/// Locally-saved favourite quotes and posts, persisted in [SharedPreferences].
///
/// Quotes and posts are identified by their integer id; the two sets are kept
/// independent so the same numeric id can be a favourite in both domains
/// without clashing.
class FavoritesState {
  const FavoritesState({required this.quoteIds, required this.postIds});

  final Set<int> quoteIds;
  final Set<int> postIds;

  bool isQuoteFavorite(int id) => quoteIds.contains(id);
  bool isPostFavorite(int id) => postIds.contains(id);
}

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier(this._preferences) : super(_loadInitial(_preferences));

  static const _quoteKey = 'fav_quote_ids';
  static const _postKey = 'fav_post_ids';

  final SharedPreferences _preferences;

  static FavoritesState _loadInitial(SharedPreferences preferences) {
    return FavoritesState(
      quoteIds: _readIds(preferences, _quoteKey),
      postIds: _readIds(preferences, _postKey),
    );
  }

  static Set<int> _readIds(SharedPreferences preferences, String key) {
    return (preferences.getStringList(key) ?? const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  Future<void> toggleQuote(int id) async {
    final next = {...state.quoteIds};
    if (!next.remove(id)) {
      next.add(id);
    }
    state = FavoritesState(quoteIds: next, postIds: state.postIds);
    await _persist(_quoteKey, next);
  }

  Future<void> togglePost(int id) async {
    final next = {...state.postIds};
    if (!next.remove(id)) {
      next.add(id);
    }
    state = FavoritesState(quoteIds: state.quoteIds, postIds: next);
    await _persist(_postKey, next);
  }

  Future<void> _persist(String key, Set<int> ids) async {
    await _preferences.setStringList(
      key,
      ids.map((id) => id.toString()).toList(growable: false),
    );
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
      return FavoritesNotifier(ref.watch(sharedPreferencesProvider));
    });

/// "Favourites only" toggles for the two Explore tabs.
final quoteFavoritesOnlyProvider = StateProvider<bool>((ref) => false);
final postFavoritesOnlyProvider = StateProvider<bool>((ref) => false);
