import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/network/api_failure.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/posts/domain/post_comment.dart';
import 'package:instant_chat/features/posts/presentation/posts_controller.dart'
    show postGatewayProvider;

final postCommentsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<PostCommentsController, PostCommentsState, String>(
      PostCommentsController.new,
    );

class PostCommentsState {
  const PostCommentsState({
    required this.comments,
    required this.nextCursor,
    this.isLoadingMore = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final List<PostComment> comments;
  final String? nextCursor;
  final bool isLoadingMore;
  final bool isSubmitting;
  final String? errorMessage;

  List<PostComment> get rootComments => comments
      .where((comment) => comment.parentCommentId == null)
      .toList(growable: false);

  List<PostComment> repliesFor(String commentId) => comments
      .where((comment) => comment.parentCommentId == commentId)
      .toList(growable: false);

  PostCommentsState copyWith({
    List<PostComment>? comments,
    String? nextCursor,
    bool clearCursor = false,
    bool? isLoadingMore,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PostCommentsState(
      comments: comments ?? this.comments,
      nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class PostCommentsController extends AsyncNotifier<PostCommentsState> {
  PostCommentsController(this.postId);

  final String postId;

  String get _accessToken {
    final session = ref.read(authControllerProvider).requireValue.session;
    if (session == null) {
      throw StateError('An authenticated session is required.');
    }
    return session.accessToken;
  }

  @override
  Future<PostCommentsState> build() async {
    final page = await ref
        .read(postGatewayProvider)
        .listComments(accessToken: _accessToken, postId: postId);
    return PostCommentsState(
      comments: page.comments,
      nextCursor: page.nextCursor,
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null) return;
    if (current.nextCursor == null ||
        current.isLoadingMore ||
        current.isSubmitting) {
      return;
    }
    state = AsyncData(current.copyWith(isLoadingMore: true, clearError: true));
    try {
      final page = await ref
          .read(postGatewayProvider)
          .listComments(
            accessToken: _accessToken,
            postId: postId,
            before: current.nextCursor,
          );
      final latest = state.requireValue;
      state = AsyncData(
        latest.copyWith(
          comments: [...latest.comments, ...page.comments],
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } catch (error) {
      final latest = state.asData?.value ?? current;
      state = AsyncData(
        latest.copyWith(
          isLoadingMore: false,
          errorMessage: _commentError(error),
        ),
      );
    }
  }

  Future<bool> create(String body, {String? parentCommentId}) async {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));
    try {
      final comment = await ref
          .read(postGatewayProvider)
          .createComment(
            accessToken: _accessToken,
            postId: postId,
            body: body,
            parentCommentId: parentCommentId,
          );
      final latest = state.requireValue;
      state = AsyncData(
        latest.copyWith(
          comments: _insertComment(latest.comments, comment),
          isSubmitting: false,
          clearError: true,
        ),
      );
      return true;
    } catch (error) {
      final latest = state.asData?.value ?? current;
      state = AsyncData(
        latest.copyWith(
          isSubmitting: false,
          errorMessage: _commentError(error),
        ),
      );
      return false;
    }
  }

  Future<int?> delete(String commentId) async {
    final current = state.requireValue;
    try {
      await ref
          .read(postGatewayProvider)
          .deleteComment(
            accessToken: _accessToken,
            postId: postId,
            commentId: commentId,
          );
      final latest = state.requireValue;
      final removed = latest.comments
          .where(
            (comment) =>
                comment.id == commentId || comment.parentCommentId == commentId,
          )
          .length;
      state = AsyncData(
        latest.copyWith(
          comments: latest.comments
              .where(
                (comment) =>
                    comment.id != commentId &&
                    comment.parentCommentId != commentId,
              )
              .toList(growable: false),
          clearError: true,
        ),
      );
      return removed;
    } catch (error) {
      final latest = state.asData?.value ?? current;
      state = AsyncData(latest.copyWith(errorMessage: _commentError(error)));
      return null;
    }
  }
}

List<PostComment> _insertComment(
  List<PostComment> comments,
  PostComment comment,
) {
  final parentID = comment.parentCommentId;
  if (parentID == null) return [comment, ...comments];
  final updated = [...comments];
  final index = updated.lastIndexWhere(
    (item) => item.id == parentID || item.parentCommentId == parentID,
  );
  updated.insert(index < 0 ? updated.length : index + 1, comment);
  return updated;
}

String _commentError(Object error) {
  if (error is ApiFailure) return error.message;
  if (error is FormatException) {
    return 'The server returned an invalid response.';
  }
  return 'Comments could not be updated.';
}
