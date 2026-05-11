import 'package:cloud_firestore/cloud_firestore.dart';

/// Claude가 생성한 맞춤 절세 분석.
class AiReport {
  final String headline;
  final String summary;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<AiAction> actions;

  const AiReport({
    required this.headline,
    required this.summary,
    required this.strengths,
    required this.weaknesses,
    required this.actions,
  });

  factory AiReport.fromJson(Map<String, dynamic> json) => AiReport(
        headline: json['headline'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        strengths: (json['strengths'] as List?)
                ?.whereType<String>()
                .toList() ??
            const [],
        weaknesses: (json['weaknesses'] as List?)
                ?.whereType<String>()
                .toList() ??
            const [],
        actions: (json['actions'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(AiAction.fromJson)
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'headline': headline,
        'summary': summary,
        'strengths': strengths,
        'weaknesses': weaknesses,
        'actions': actions.map((a) => a.toJson()).toList(),
      };
}

class AiAction {
  final String title;
  final String detail;
  final String priority; // 'high' | 'medium' | 'low'

  const AiAction({
    required this.title,
    required this.detail,
    required this.priority,
  });

  factory AiAction.fromJson(Map<String, dynamic> json) => AiAction(
        title: json['title'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        priority: json['priority'] as String? ?? 'medium',
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'detail': detail,
        'priority': priority,
      };
}

/// 캐시된 분석 — 입력 해시가 일치하면 재사용.
class CachedAiReport {
  final String inputHash;
  final AiReport report;
  final DateTime generatedAt;

  const CachedAiReport({
    required this.inputHash,
    required this.report,
    required this.generatedAt,
  });

  factory CachedAiReport.fromJson(Map<String, dynamic> json) {
    final ts = json['generatedAt'];
    final t = ts is Timestamp ? ts.toDate() : DateTime.now();
    return CachedAiReport(
      inputHash: json['inputHash'] as String? ?? '',
      report: AiReport.fromJson(
          (json['report'] as Map?)?.cast<String, dynamic>() ?? const {}),
      generatedAt: t,
    );
  }

  Map<String, dynamic> toJson() => {
        'inputHash': inputHash,
        'report': report.toJson(),
        'generatedAt': FieldValue.serverTimestamp(),
      };
}
