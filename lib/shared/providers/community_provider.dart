import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/community/community_comment.dart';
import '../../features/community/community_post.dart';
import '../services/community_service.dart';

part 'community_provider.g.dart';

@riverpod
CommunityService communityService(CommunityServiceRef ref) {
  return CommunityService(FirebaseFirestore.instance);
}

@riverpod
Stream<List<CommunityPost>> communityPosts(CommunityPostsRef ref) {
  return ref.read(communityServiceProvider).watchAll();
}

@riverpod
Stream<CommunityPost?> communityPost(CommunityPostRef ref, String id) {
  return ref.read(communityServiceProvider).watchById(id);
}

@riverpod
Stream<List<CommunityComment>> communityComments(
  CommunityCommentsRef ref,
  String postId,
) {
  return ref.read(communityServiceProvider).watchComments(postId);
}
