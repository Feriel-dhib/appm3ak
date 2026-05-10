import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../providers/auth_providers.dart';
import 'community_locations_screen.dart';
import 'community_posts_screen.dart';
import 'help_requests_screen.dart';

/// Hub Communauté : publications, lieux accessibles (`/lieux`), demandes d'aide.
class CommunityMainScreen extends ConsumerStatefulWidget {
  const CommunityMainScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  ConsumerState<CommunityMainScreen> createState() =>
      _CommunityMainScreenState();
}

class _CommunityMainScreenState extends ConsumerState<CommunityMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final i = widget.initialTabIndex.clamp(0, 2);
    _tabController = TabController(length: 3, vsync: this, initialIndex: i);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CommunityMainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      final i = widget.initialTabIndex.clamp(0, 2);
      if (_tabController.index != i) {
        _tabController.animateTo(i);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(strings.community),
        actions: [
          IconButton(
            tooltip: strings.messagerieInboxTitle,
            onPressed: () => context.push('/messages'),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
          IconButton(
            tooltip: strings.communityAiEntryTooltip,
            onPressed: () => context.push('/community-ai-entry'),
            icon: const Icon(Icons.auto_awesome_outlined),
          ),
          IconButton(
            tooltip: strings.communityCircleOfTrust,
            onPressed: () => context.push('/community-contacts'),
            icon: const Icon(Icons.group_outlined),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.forum_outlined), text: strings.hubZonePosts),
            Tab(icon: const Icon(Icons.place_outlined), text: strings.communityPlaces),
            Tab(icon: const Icon(Icons.help_outline), text: strings.helpRequests),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CommunityPostsScreen(),
          CommunityLocationsScreen(),
          HelpRequestsScreen(),
        ],
      ),
    );
  }
}
