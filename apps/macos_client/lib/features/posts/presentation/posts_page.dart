import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/platform/macos_file_actions.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_controller.dart';
import 'package:instant_chat/features/news/presentation/daily_brief_rail.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';
import 'package:instant_chat/features/posts/presentation/explore_feed.dart';
import 'package:instant_chat/features/posts/presentation/explore_header.dart';
import 'package:instant_chat/features/posts/presentation/post_action_dialogs.dart';
import 'package:instant_chat/features/posts/presentation/post_card.dart';
import 'package:instant_chat/features/posts/presentation/post_composer_bar.dart';
import 'package:instant_chat/features/posts/presentation/post_composer_dialog.dart';
import 'package:instant_chat/features/posts/presentation/post_image_grid.dart';
import 'package:instant_chat/features/posts/presentation/posts_controller.dart';

class PostsPage extends ConsumerStatefulWidget {
  const PostsPage({super.key});

  @override
  ConsumerState<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends ConsumerState<PostsPage> {
  final _scrollController = ScrollController();
  var _selectedTab = ExploreFeedTab.forYou;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadNearBottom);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadNearBottom)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).asData?.value.session;
    if (session == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final posts = ref.watch(postsControllerProvider);
    final contactIds = ref.watch(
      contactsControllerProvider.select(
        (value) => value.asData?.value.contacts
            .map((contact) => contact.user.id)
            .toSet(),
      ),
    );
    return posts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => ExploreFailure(
        onRetry: () => ref.invalidate(postsControllerProvider),
      ),
      data: (state) {
        final visiblePosts = filterExplorePosts(
          state.posts,
          selectedTab: _selectedTab,
          contactUserIds: contactIds ?? const <String>{},
        );
        final feed = _feed(state: state, posts: visiblePosts, session: session);
        return LayoutBuilder(
          builder: (context, constraints) {
            final showBrief =
                constraints.maxWidth >= RetroMetrics.dailyBriefBreakpoint;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _mainContent(session, state, feed)),
                if (showBrief) ...[
                  VerticalDivider(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  SizedBox(
                    width: RetroMetrics.dailyBriefWidth,
                    child: DailyBriefRail(accessToken: session.accessToken),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _mainContent(AuthSession session, PostsState state, Widget feed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExploreHeader(
          selectedTab: _selectedTab,
          onTabSelected: (tab) => setState(() => _selectedTab = tab),
          onRefresh: () => ref.read(postsControllerProvider.notifier).refresh(),
          onCreate: () => showPostComposer(context),
        ),
        Expanded(child: _withError(state, feed)),
      ],
    );
  }

  Widget _feed({
    required PostsState state,
    required List<PublicPost> posts,
    required AuthSession session,
  }) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: LayoutBuilder(
        builder: (context, constraints) => ListView.separated(
          key: const PageStorageKey('explore-feed'),
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 28),
          itemCount:
              1 +
              (posts.isEmpty ? 1 : posts.length) +
              (state.isLoadingMore ? 1 : 0),
          separatorBuilder: (context, index) {
            if (index == 0) return const SizedBox.shrink();
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: RetroMetrics.exploreContentMaxWidth,
                ),
                child: Divider(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            );
          },
          itemBuilder: (context, index) {
            if (index == 0) {
              return PostComposerBar(
                user: session.user,
                accessToken: session.accessToken,
                onCreate: () => showPostComposer(context),
              );
            }
            if (posts.isEmpty) {
              final emptyHeight =
                  (constraints.maxHeight - RetroMetrics.exploreComposerHeight)
                      .clamp(0, double.infinity)
                      .toDouble();
              return SizedBox(
                height: emptyHeight,
                child: ExploreEmpty(
                  label: _selectedTab == ExploreFeedTab.contacts
                      ? 'Posts from your contacts will appear here.'
                      : 'Be the first to share something.',
                  onCreate: () => showPostComposer(context),
                ),
              );
            }
            final postIndex = index - 1;
            if (postIndex == posts.length) {
              return const ExploreLoadingMore();
            }
            final post = posts[postIndex];
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: RetroMetrics.exploreContentMaxWidth,
                ),
                child: PostCard(
                  post: post,
                  accessToken: session.accessToken,
                  isOwnPost: post.author.id == session.user.id,
                  onAction: (action) => _handleAction(action, post),
                  onDownloadImage: _downloadImage,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _withError(PostsState state, Widget feed) {
    final message = state.errorMessage;
    if (message == null) return feed;
    return Stack(
      children: [
        feed,
        Positioned(
          left: 20,
          right: 20,
          top: 10,
          child: Material(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(RetroMetrics.corner),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(message, textAlign: TextAlign.center),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(PostAction action, PublicPost post) async {
    final controller = ref.read(postsControllerProvider.notifier);
    switch (action) {
      case PostAction.delete:
        if (await confirmDeletePost(context) && mounted) {
          await controller.delete(post.id);
        }
      case PostAction.report:
        final reason = await askReportReason(context);
        if (reason != null && mounted) {
          final reported = await controller.report(post.id, reason);
          if (reported && mounted) _notice('Report submitted.');
        }
    }
  }

  Future<void> _downloadImage(PublicPostImage image) async {
    final actions = ref.read(localFileActionsProvider);
    try {
      final path = await actions.chooseDownloadPath(
        postImageDownloadFilename(image),
      );
      if (!mounted || path == null) return;
      final bytes = await ref
          .read(postsControllerProvider.notifier)
          .downloadImage(image);
      await actions.writeDownloadFile(path, bytes);
    } catch (_) {
      if (mounted) _notice('Image could not be saved.');
    }
  }

  void _loadNearBottom() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 320) {
      ref.read(postsControllerProvider.notifier).loadMore();
    }
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }
}
