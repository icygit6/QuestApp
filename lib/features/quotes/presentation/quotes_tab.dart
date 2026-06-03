import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../domain/quote_entity.dart';
import 'quotes_provider.dart';

class QuotesTab extends ConsumerWidget {
  const QuotesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quotesProvider);
    final query = ref.watch(quotesSearchProvider);

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: () =>
          ref.read(quotesProvider.notifier).load(refresh: true, query: query),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          SearchBar(
            hintText: 'Search quotes',
            leading: const Icon(Icons.search_rounded, color: AppColors.gold),
            onChanged: (value) =>
                ref.read(quotesSearchProvider.notifier).state = value,
            onSubmitted: (value) => ref
                .read(quotesProvider.notifier)
                .load(refresh: true, query: value),
            trailing: query.isEmpty
                ? null
                : [
                    IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        ref.read(quotesSearchProvider.notifier).state = '';
                        ref.read(quotesProvider.notifier).load(refresh: true);
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
            backgroundColor: WidgetStatePropertyAll(context.palette.surface),
            side: WidgetStatePropertyAll(
              BorderSide(color: context.palette.border),
            ),
            elevation: const WidgetStatePropertyAll(0),
          ),
          const SizedBox(height: 12),
          if (state.status == QuotesStatus.loading && state.quotes.isEmpty)
            const LinearProgressIndicator(color: AppColors.gold),
          if (state.isRefreshing)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: LinearProgressIndicator(color: AppColors.gold),
            ),
          if (state.status == QuotesStatus.error && state.quotes.isEmpty)
            SizedBox(
              height: 420,
              child: QuestErrorWidget(
                message: state.message ?? 'Failed to load quotes.',
                onRetry: () =>
                    ref.read(quotesProvider.notifier).load(refresh: true),
              ),
            )
          else if (state.status == QuotesStatus.loaded && state.quotes.isEmpty)
            const QuestEmptyWidget(
              title: 'No quotes found',
              subtitle: 'Try a different search keyword.',
            )
          else
            ...state.quotes.asMap().entries.map(
              (entry) => _QuoteCard(
                quote: entry.value,
                index: entry.key,
                onTap: () => context.push(
                  '/explore/quotes/${entry.value.id}',
                  extra: entry.value,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.quote,
    required this.index,
    required this.onTap,
  });

  final QuoteEntity quote;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"${quote.body}"',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      quote.author,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  const Icon(
                    Icons.favorite_rounded,
                    size: 16,
                    color: AppColors.hard,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    quote.favoritesCount.toString(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              if (quote.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in quote.tags.take(3))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.palette.surfaceAlt,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '#$tag',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 40).ms).slideY(begin: 0.05);
  }
}
