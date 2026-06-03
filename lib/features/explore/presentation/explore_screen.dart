import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../posts/presentation/posts_tab.dart';
import '../../quotes/presentation/quotes_tab.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.explore),
          bottom: const TabBar(
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.gold,
            tabs: [
              Tab(text: AppStrings.quotes),
              Tab(text: AppStrings.posts),
            ],
          ),
        ),
        body: const TabBarView(children: [QuotesTab(), PostsTab()]),
      ),
    );
  }
}
