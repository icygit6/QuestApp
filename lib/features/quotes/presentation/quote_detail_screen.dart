import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../domain/quote_entity.dart';
import 'quotes_provider.dart';

class QuoteDetailScreen extends ConsumerWidget {
  const QuoteDetailScreen({
    required this.quoteId,
    super.key,
    this.initialQuote,
  });

  final int quoteId;
  final QuoteEntity? initialQuote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quote = initialQuote;
    if (quote != null) {
      return _QuoteDetailBody(quote: quote);
    }

    final asyncQuote = ref.watch(quoteDetailProvider(quoteId));
    return asyncQuote.when(
      data: (loaded) => _QuoteDetailBody(quote: loaded),
      loading: () => const _QuoteDetailLoading(),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: context.pop,
          ),
          title: const Text('Quote'),
        ),
        body: QuestErrorWidget(
          message: error.toString(),
          onRetry: () => ref.refresh(quoteDetailProvider(quoteId)),
        ),
      ),
    );
  }
}

class _QuoteDetailLoading extends StatelessWidget {
  const _QuoteDetailLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Quote'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(18),
        child: LinearProgressIndicator(color: AppColors.gold),
      ),
    );
  }
}

class _QuoteDetailBody extends StatelessWidget {
  const _QuoteDetailBody({required this.quote});

  final QuoteEntity quote;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Quote'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Text(
                '"${quote.body}"',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ).animate().fadeIn().slideY(begin: 0.06),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.person_rounded, color: AppColors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    quote.author,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.favorite_rounded, color: AppColors.hard),
                const SizedBox(width: 6),
                Text(
                  '${quote.favoritesCount} favorites',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            if (quote.tags.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in quote.tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
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
    );
  }
}
