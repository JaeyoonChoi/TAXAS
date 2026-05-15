import '../../core/services/tax_calculator_service.dart';
import '../models/user_info_state.dart';
import '../widgets/common_widgets.dart';

/// 사용자 정보 + 계산 결과를 세무사 상담용 텍스트로 포맷.
///
/// [advisorName]을 지정하면 헤더에 추천 인사말 한 줄 추가.
String buildReportShareText(
  UserInfoState userInfo,
  TaxResult result, {
  String? advisorName,
}) {
  final f = userInfo.family;
  final a = userInfo.assets;
  final priorGiftTotal =
      userInfo.giftHistory.fold<int>(0, (s, g) => s + g.amount);

  final children = f.childAges.asMap().entries.map((e) {
    final age = e.value;
    return '자녀${e.key + 1} ${age}세${age < 19 ? '(미성년)' : ''}';
  }).join(', ');

  final optimalPlan = result.optimalGiftPlan.entries
      .map((e) => '${e.key} ${formatKoreanCurrency(e.value)}')
      .join(', ');

  final buf = StringBuffer();
  if (advisorName != null) {
    buf
      ..writeln('안녕하세요, $advisorName 세무사님.')
      ..writeln('ATAX 절세 시뮬레이션 결과를 보내드리며 상담 문의드립니다.')
      ..writeln();
  }
  buf
    ..writeln('[ATAX 절세 시뮬레이션 결과]')
    ..writeln('')
    ..writeln('● 가족 정보')
    ..writeln('- 본인 나이: ${f.ownerAge}세')
    ..writeln('- 배우자: ${f.hasSpouse ? "있음" : "없음"}')
    ..writeln('- 자녀: ${f.childCount}명${children.isNotEmpty ? " ($children)" : ""}')
    ..writeln('')
    ..writeln('● 자산')
    ..writeln('- 부동산: ${formatKoreanCurrency(a.realEstate)}')
    ..writeln('- 금융자산: ${formatKoreanCurrency(a.financial)}')
    ..writeln('- 기타자산: ${formatKoreanCurrency(a.other)}')
    ..writeln('- 채무: ${formatKoreanCurrency(a.debt)}')
    ..writeln('- 총자산(채무 차감 전): ${formatKoreanCurrency(a.totalGross)}')
    ..writeln('- 순자산: ${formatKoreanCurrency(a.totalNet)}')
    ..writeln('')
    ..writeln('● 사전증여 이력 (최근 10년)')
    ..writeln('- 합계: ${formatKoreanCurrency(priorGiftTotal)}')
    ..writeln('')
    ..writeln('● 예상 세액 (단순 시뮬레이션)')
    ..writeln('- 대비 X 시: ${formatKoreanCurrency(result.noPlanningTax)}')
    ..writeln('- 사전증여 활용 시: ${formatKoreanCurrency(result.withPlanningTax)}')
    ..writeln('- 절감 가능 금액: ${formatKoreanCurrency(result.planningSavings)}');

  if (optimalPlan.isNotEmpty) {
    buf
      ..writeln('')
      ..writeln('● 권장 사전증여 분배')
      ..writeln('- $optimalPlan');
  }

  buf
    ..writeln('')
    ..writeln('※ 본 결과는 ATAX의 단순화된 시뮬레이션이며,')
    ..writeln('실제 신고 시 전문가 상담이 필요합니다.')
    ..writeln('')
    ..writeln('https://taxas-bd85b.web.app');

  return buf.toString();
}
