import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';
import 'package:instant_chat/features/posts/presentation/explore_discovery_cards.dart';

class ExploreDiscoveryRail extends StatefulWidget {
  const ExploreDiscoveryRail({
    required this.posts,
    required this.accessToken,
    required this.currentUserId,
    required this.query,
    required this.onSearchChanged,
    super.key,
  });

  final List<PublicPost> posts;
  final String accessToken;
  final String currentUserId;
  final String query;
  final ValueChanged<String> onSearchChanged;

  @override
  State<ExploreDiscoveryRail> createState() => _ExploreDiscoveryRailState();
}

class _ExploreDiscoveryRailState extends State<ExploreDiscoveryRail> {
  late final _searchController = TextEditingController(text: widget.query);

  @override
  void didUpdateWidget(covariant ExploreDiscoveryRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _searchController.text) {
      _searchController.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final feature = _featuredPost(widget.posts);
    final topics = widget.posts.where((post) => post != feature).take(3);
    final people = _suggestedAuthors(
      widget.posts,
      currentUserId: widget.currentUserId,
    );
    return ColoredBox(
      color: RetroColors.glass,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          SizedBox(
            height: RetroMetrics.exploreSearchHeight,
            child: TextField(
              key: const Key('explore-search-field'),
              controller: _searchController,
              onChanged: widget.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                suffixIcon: widget.query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          widget.onSearchChanged('');
                        },
                        icon: const Icon(Icons.close_rounded, size: 16),
                      ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: colors.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: colors.outlineVariant),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          DiscoveryRailSection(
            title: 'Popular today',
            child: feature == null
                ? const DiscoveryRailEmpty(
                    label: 'Popular posts will appear here.',
                  )
                : Column(
                    children: [
                      DiscoveryFeaturedPost(
                        post: feature,
                        accessToken: widget.accessToken,
                        onTap: () => _showAuthor(feature.author.username),
                      ),
                      for (final post in topics)
                        DiscoveryTopicRow(
                          post: post,
                          onTap: () => _showAuthor(post.author.username),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          DiscoveryRailSection(
            title: 'People you may know',
            child: people.isEmpty
                ? const DiscoveryRailEmpty(
                    label: 'New people will appear here.',
                  )
                : Column(
                    children: [
                      for (final author in people)
                        DiscoveryPersonRow(
                          post: author,
                          accessToken: widget.accessToken,
                          onView: () => _showAuthor(author.author.username),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showAuthor(String username) {
    _searchController.text = username;
    widget.onSearchChanged(username);
  }
}

PublicPost? _featuredPost(List<PublicPost> posts) {
  for (final post in posts) {
    if (post.images.isNotEmpty) return post;
  }
  return posts.firstOrNull;
}

List<PublicPost> _suggestedAuthors(
  List<PublicPost> posts, {
  required String currentUserId,
}) {
  final seen = <String>{currentUserId};
  return posts
      .where((post) => seen.add(post.author.id))
      .take(3)
      .toList(growable: false);
}
