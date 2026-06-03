import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/profile_remote_datasource.dart';
import '../data/profile_repository_impl.dart';
import '../domain/profile_entity.dart';
import '../domain/profile_repository.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>(
  (ref) => ProfileRemoteDataSource(ref.watch(dioClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider)),
);

final profileProvider = FutureProvider.family<ProfileEntity, int>((
  ref,
  userId,
) async {
  final result = await ref.watch(profileRepositoryProvider).getProfile(userId);
  return result.fold((failure) => throw failure.message, (profile) => profile);
});
