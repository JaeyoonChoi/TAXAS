// Custom flutter_bootstrap.js — Service Worker 등록을 비활성화.
// 개발/이터레이션 단계에서 SW 캐시 때문에 새 빌드가 즉시 반영되지 않는 문제 방지.
// 안정화 후 SW를 다시 켜고 싶으면 `serviceWorkerVersion: null` 줄을 제거하면 된다.

{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: null,
  },
});
