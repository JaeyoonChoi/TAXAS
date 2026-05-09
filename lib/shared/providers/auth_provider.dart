import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/admin_config.dart';
import '../../firebase_options.dart';

part 'auth_provider.g.dart';

/// FirebaseAuth 인스턴스. Firebase 미설정(useFirebase=false)일 때도
/// 화면이 컴파일·렌더링되도록 lazy하게 접근한다.
@riverpod
FirebaseAuth firebaseAuth(FirebaseAuthRef ref) {
  return FirebaseAuth.instance;
}

/// 현재 인증 상태를 스트리밍. 로그아웃 상태면 User?의 null.
@riverpod
Stream<User?> authState(AuthStateRef ref) {
  if (!useFirebase) {
    return Stream.value(null);
  }
  return ref.watch(firebaseAuthProvider).authStateChanges();
}

/// 로그인된 사용자의 uid (없으면 null).
@riverpod
String? currentUid(CurrentUidRef ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
}

/// 현재 사용자가 관리자인지 — 이메일 allowlist 기반.
@riverpod
bool isAdmin(IsAdminRef ref) {
  final email = ref.watch(authStateProvider).valueOrNull?.email;
  return email != null && kAdminEmails.contains(email);
}

/// 인증 작업(로그인·가입·로그아웃)을 수행하는 컨트롤러.
@riverpod
class AuthController extends _$AuthController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      await ref.read(firebaseAuthProvider).signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      state = const AsyncData(null);
    } on FirebaseAuthException catch (e, st) {
      state = AsyncError(_translateError(e), st);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      await ref.read(firebaseAuthProvider).createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      state = const AsyncData(null);
    } on FirebaseAuthException catch (e, st) {
      state = AsyncError(_translateError(e), st);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signOut() async {
    await ref.read(firebaseAuthProvider).signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncLoading();
    try {
      await ref.read(firebaseAuthProvider).sendPasswordResetEmail(
            email: email.trim(),
          );
      state = const AsyncData(null);
    } on FirebaseAuthException catch (e, st) {
      state = AsyncError(_translateError(e), st);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// FirebaseAuthException 코드를 한글 메시지로 변환.
String _translateError(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return '올바른 이메일 형식이 아닙니다.';
    case 'user-disabled':
      return '비활성화된 계정입니다.';
    case 'user-not-found':
      return '존재하지 않는 계정입니다.';
    case 'wrong-password':
    case 'invalid-credential':
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    case 'email-already-in-use':
      return '이미 가입된 이메일입니다.';
    case 'weak-password':
      return '비밀번호는 6자 이상이어야 합니다.';
    case 'network-request-failed':
      return '네트워크 연결을 확인해주세요.';
    case 'too-many-requests':
      return '잠시 후 다시 시도해주세요.';
    default:
      return e.message ?? '인증 중 오류가 발생했습니다. (${e.code})';
  }
}
