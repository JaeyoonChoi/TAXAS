import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 세무사 탭 — 로톡 스타일의 전문가 검색·매칭 (mock 데이터).
///
/// 추후 Firestore `experts/` 컬렉션 + 검색·예약 기능으로 확장 예정.
class ExpertScreen extends StatefulWidget {
  const ExpertScreen({super.key});

  @override
  State<ExpertScreen> createState() => _ExpertScreenState();
}

class _ExpertScreenState extends State<ExpertScreen> {
  String _selectedSpec = '전체';
  static const _specs = ['전체', '상속세', '증여세', '양도세', '가업승계'];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedSpec == '전체'
        ? _experts
        : _experts.where((e) => e.specs.contains(_selectedSpec)).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  Text(
                    'Tax Advisors',
                    style: AppText.sectionTitle(size: 24),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                '상속·증여·양도세 전문 세무사를 찾아보세요',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            // 필터 칩
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _specs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final s = _specs[i];
                  final active = s == _selectedSpec;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSpec = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            active ? AppColors.textPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active
                              ? AppColors.textPrimary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),

            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('해당 분야 세무사가 없습니다.',
                          style:
                              TextStyle(color: AppColors.textTertiary)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (ctx, i) => _ExpertRow(
                        expert: filtered[i],
                        onTap: () => Navigator.of(ctx).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                _ExpertDetailScreen(expert: filtered[i]),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 가로형 세무사 카드 ───────────────────────────────────

class _ExpertRow extends StatelessWidget {
  final _Expert expert;
  final VoidCallback onTap;

  const _ExpertRow({required this.expert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: expert.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Text(
                  expert.name.substring(0, 1),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: expert.accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${expert.name} 세무사',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· ${expert.years}년차',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expert.tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: expert.specs
                          .take(3)
                          .map((s) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 13, color: AppColors.goldDeep),
                        const SizedBox(width: 2),
                        Text(
                          expert.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${expert.reviewCount})',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 2),
                        Text(
                          expert.region,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 세무사 상세 화면 ─────────────────────────────────────

class _ExpertDetailScreen extends StatelessWidget {
  final _Expert expert;
  const _ExpertDetailScreen({required this.expert});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('세무사 프로필'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 프로필 헤더
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: expert.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    expert.name.substring(0, 1),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: expert.accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${expert.name} 세무사',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${expert.years}년차 · ${expert.region}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, size: 18, color: AppColors.goldDeep),
                    const SizedBox(width: 4),
                    Text(
                      expert.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· 후기 ${expert.reviewCount}개',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _section('전문 분야', expert.specs.join(' · ')),
          _section('소개', expert.bio),
          _section('주요 경력', expert.career),
          _section('상담 비용', expert.fee),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showContact(context),
            icon: const Icon(Icons.phone),
            label: const Text('상담 문의하기'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.navyBase,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String label, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContact(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${expert.name} 세무사 상담 문의',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.phone_outlined,
                      size: 18, color: AppColors.navyBase),
                  const SizedBox(width: 8),
                  SelectableText(
                    expert.phone,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.mail_outline,
                      size: 18, color: AppColors.navyBase),
                  const SizedBox(width: 8),
                  SelectableText(
                    expert.email,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '※ 본 정보는 데모용 mock 데이터입니다. 실제 연락은 정식 매칭 서비스 연동 후 가능합니다.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Mock 데이터 ──────────────────────────────────────────

class _Expert {
  final String name;
  final int years;
  final String region;
  final List<String> specs;
  final String tagline;
  final String bio;
  final String career;
  final String fee;
  final String phone;
  final String email;
  final double rating;
  final int reviewCount;
  final Color accentColor;

  const _Expert({
    required this.name,
    required this.years,
    required this.region,
    required this.specs,
    required this.tagline,
    required this.bio,
    required this.career,
    required this.fee,
    required this.phone,
    required this.email,
    required this.rating,
    required this.reviewCount,
    required this.accentColor,
  });
}

const _experts = <_Expert>[
  _Expert(
    name: '김상속',
    years: 22,
    region: '서울 강남',
    specs: ['상속세', '증여세', '가업승계'],
    tagline: '대형 로펌 세무팀 출신, 30억 이상 자산가 상속 전문',
    bio: '복잡한 상속·증여 케이스를 22년간 다뤄왔습니다. 부동산·금융자산이 혼합된 자산가의 상속 설계와 가업승계 컨설팅이 주력입니다.',
    career: '前 대형 회계법인 세무자문 / 한국세무사회 정회원 / 가업승계연구회 자문위원',
    fee: '초회 상담 무료 (30분) / 정식 자문 시간당 30만원~',
    phone: '010-1111-2222',
    email: 'sangsok@example.com',
    rating: 4.9,
    reviewCount: 184,
    accentColor: AppColors.navyBase,
  ),
  _Expert(
    name: '박증여',
    years: 14,
    region: '서울 마포',
    specs: ['증여세', '양도세'],
    tagline: '청년 1세대 자산가의 사전증여 플래닝 특화',
    bio: '30~50대 자산가의 사전증여를 통한 절세 전략에 집중합니다. 시기 분산·자녀별 한도 활용 시뮬레이션을 자세히 설명해드립니다.',
    career: '국세청 출신 / 세무법인 〇〇 파트너',
    fee: '초회 상담 5만원 / 1회 컨설팅 패키지 80만원',
    phone: '010-3333-4444',
    email: 'gift@example.com',
    rating: 4.8,
    reviewCount: 96,
    accentColor: AppColors.goldDeep,
  ),
  _Expert(
    name: '이양도',
    years: 9,
    region: '경기 분당',
    specs: ['양도세', '부동산'],
    tagline: '다주택자·재개발/재건축 양도세 전문',
    bio: '다주택자 양도세 중과 회피 전략, 1세대 1주택 비과세 요건 검토에 강점. 부동산 거래 직전 컨설팅을 받으면 절세 효과가 큽니다.',
    career: '한국공인회계사회 / 한국세무사회 회원 / 부동산세제연구회 활동',
    fee: '단건 상담 10만원 / 거래 직전 검토 50만원',
    phone: '010-5555-6666',
    email: 'yangdo@example.com',
    rating: 4.7,
    reviewCount: 73,
    accentColor: AppColors.success,
  ),
  _Expert(
    name: '최가업',
    years: 18,
    region: '서울 종로',
    specs: ['가업승계', '상속세', '법인세'],
    tagline: '중소기업 가업승계 컨설팅 18년',
    bio: '제조업·서비스업 가업승계 컨설팅 전문. 가업상속공제 요건 사전 점검부터 사후관리까지 전 과정 지원.',
    career: '前 중소기업청 세무자문위원 / 가업승계지원센터 자문',
    fee: '초회 상담 무료 / 가업승계 패키지 별도 견적',
    phone: '010-7777-8888',
    email: 'gaup@example.com',
    rating: 4.9,
    reviewCount: 142,
    accentColor: AppColors.error,
  ),
  _Expert(
    name: '정세무',
    years: 7,
    region: '서울 송파',
    specs: ['증여세', '상속세'],
    tagline: '소액 자산가 증여·상속 입문 컨설팅',
    bio: '5억~20억 규모 자산가에게 부담 없는 가격으로 증여·상속 기초 컨설팅을 제공합니다. 첫 상담을 부담 없이 받고 싶은 분께 추천.',
    career: '한국세무사회 정회원 / 세무법인 △△ 소속',
    fee: '초회 상담 3만원 / 1시간 코칭 패키지 25만원',
    phone: '010-9999-0000',
    email: 'taxas@example.com',
    rating: 4.6,
    reviewCount: 41,
    accentColor: AppColors.info,
  ),
];
