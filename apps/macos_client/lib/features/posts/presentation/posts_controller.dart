import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/network/api_failure.dart';
import 'package:instant_chat/core/network/dio_provider.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/posts/data/dio_post_gateway.dart';
import 'package:instant_chat/features/posts/domain/post_gateway.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';

final postGatewayProvider = Provider<PostGateway>((ref) {
  return DioPostGateway(ref.watch(dioProvider));
});

final postsControllerProvider =
    AsyncNotifierProvider.autoDispose<PostsController, PostsState>(
      PostsController.new,
    );

class PostsState {
  const PostsState({
    required this.posts,
    required this.nextCursor,
    this.isLoadingMore = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final List<PublicPost> posts;
  final String? nextCursor;
  final bool isLoadingMore;
  final bool isSubmitting;
  final String? errorMessage;

  PostsState copyWith({
    List<PublicPost>? posts,
    String? nextCursor,
    bool clearCursor = false,
    bool? isLoadingMore,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class PostsController extends AsyncNotifier<PostsState> {
  PostGateway get _gateway => ref.read(postGatewayProvider);

  String get _accessToken {
    final session = ref.read(authControllerProvider).requireValue.session;
    if (session == null) {
      throw StateError('An authenticated session is required.');
    }
    return session.accessToken;
  }

  @override
  Future<PostsState> build() async {
    final page = await _gateway.list(accessToken: _accessToken);
    return PostsState(posts: page.posts, nextCursor: page.nextCursor);
  }

  Future<void> refresh() async {
    final previous = state.asData?.value;
    try {
      final page = await _gateway.list(accessToken: _accessToken);
      state = AsyncData(
        PostsState(posts: page.posts, nextCursor: page.nextCursor),
      );
    } catch (error, stackTrace) {
      if (previous == null) {
        state = AsyncError(error, stackTrace);
      } else {
        state = AsyncData(previous.copyWith(errorMessage: _message(error)));
      }
    }
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null ||
        current.nextCursor == null ||
        current.isLoadingMore ||
        current.isSubmitting) {
      return;
    }
    state = AsyncData(current.copyWith(isLoadingMore: true, clearError: true));
    try {
      final page = await _gateway.list(
        accessToken: _accessToken,
        before: current.nextCursor,
      );
      state = AsyncData(
        current.copyWith(
          posts: [...current.posts, ...page.posts],
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(isLoadingMore: false, errorMessage: _message(error)),
      );
    }
  }

  Future<bool> create(String body, List<String> imagePaths) async {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));
    try {
      final post = await _gateway.create(
        accessToken: _accessToken,
        body: body,
        imagePaths: imagePaths,
      );
      state = AsyncData(
        current.copyWith(
          posts: [post, ...current.posts],
          isSubmitting: false,
          clearError: true,
        ),
      );
      return true;
    } catch (error) {
      state = AsyncData(
        current.copyWith(isSubmitting: false, errorMessage: _message(error)),
      );
      return false;
    }
  }

  Future<bool> delete(String postId) {
    return _mutate(
      () => _gateway.delete(accessToken: _accessToken, postId: postId),
      (current) => current.posts
          .where((post) => post.id != postId)
          .toList(growable: false),
    );
  }

  Future<List<int>> downloadImage(PublicPostImage image) {
    return _gateway.downloadImage(accessToken: _accessToken, image: image);
  }

  Future<bool> report(String postId, String reason) {
    return _mutate(
      () => _gateway.report(
        accessToken: _accessToken,
        postId: postId,
        reason: reason,
      ),
    );
  }

  Future<bool> _mutate(
    Future<void> Function() action, [
    List<PublicPost> Function(PostsState current)? updatePosts,
  ]) async {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));
    try {
      await action();
      state = AsyncData(
        current.copyWith(
          posts: updatePosts?.call(current),
          isSubmitting: false,
          clearError: true,
        ),
      );
      return true;
    } catch (error) {
      state = AsyncData(
        current.copyWith(isSubmitting: false, errorMessage: _message(error)),
      );
      return false;
    }
  }
}

String _message(Object error) {
  if (error is ApiFailure) {
    return error.message;
  }
  if (error is FormatException) {
    return 'The server returned an invalid response.';
  }
  return 'The request could not be completed.';
}
