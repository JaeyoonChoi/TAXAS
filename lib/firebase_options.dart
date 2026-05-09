// Firebase configuration for Taxas.
//
// 이 파일은 placeholder입니다. 실제 Firebase 프로젝트 설정 후 다음 중 하나로 교체하세요:
//
// 옵션 1 (권장) — flutterfire CLI 자동 생성:
//   $ dart pub global activate flutterfire_cli
//   $ flutterfire configure --project=<your-firebase-project-id>
//   → 이 파일을 자동으로 덮어씁니다.
//
// 옵션 2 — 수동: Firebase 콘솔에서 받은 SDK 정보로 아래 빈 문자열을 채워넣으세요.
//
// `useFirebase = false`인 동안에는 main.dart가 Firebase 초기화를 건너뛰므로
// 인증 없이 로컬에서만 동작합니다 (Firestore 동기화 비활성화).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase 설정이 완료되었는지 토글하는 플래그.
/// 콘솔 작업 + 아래 옵션 채움이 끝난 뒤 `true`로 변경하세요.
const bool useFirebase = true;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions.currentPlatform: 지원하지 않는 플랫폼입니다.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC0vW3ijyROsk3Dmcjw3ijZNfBs6tuTXEg',
    appId: '1:722058595121:web:110e92f76ac3f1410abe10',
    messagingSenderId: '722058595121',
    projectId: 'taxas-bd85b',
    authDomain: 'taxas-bd85b.firebaseapp.com',
    storageBucket: 'taxas-bd85b.firebasestorage.app',
    measurementId: 'G-XR8CZM89N1',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDfmWzEwDN9AdyhHa7zYQ9tUkHJvQAL17I',
    appId: '1:722058595121:android:03e63780f568a5e40abe10',
    messagingSenderId: '722058595121',
    projectId: 'taxas-bd85b',
    storageBucket: 'taxas-bd85b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDnX9F_5gNC5udnEB8lJ5WPGWTIuaMg-UI',
    appId: '1:722058595121:ios:c2df20739f2f36150abe10',
    messagingSenderId: '722058595121',
    projectId: 'taxas-bd85b',
    storageBucket: 'taxas-bd85b.firebasestorage.app',
    iosBundleId: 'com.taxas.taxas',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '',
    projectId: '',
    storageBucket: '',
    iosBundleId: 'com.example.taxas',
  );
}