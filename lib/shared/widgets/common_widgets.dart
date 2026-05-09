import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// 섹션 헤더 라벨
class SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;

  const SectionLabel(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: color ?? AppColors.navyBase,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// 정보 카드 (아이콘 + 제목 + 값)
class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? valueColor;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDeep.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.navyBase).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.navyBase,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: valueColor ?? AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

/// 그라디언트 배경 컨테이너
class GradientContainer extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const GradientContainer({
    super.key,
    required this.child,
    this.gradient,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.navyGradient,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

/// 진행 단계 표시 위젯
class StepProgressBar extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final List<String> labels;

  const StepProgressBar({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final isDone = i < currentStep;
        final isCurrent = i == currentStep;
        return Expanded(
          child: Row(
            children: [
              _StepDot(
                index: i + 1,
                isDone: isDone,
                isCurrent: isCurrent,
                label: i < labels.length ? labels[i] : '',
              ),
              if (i < totalSteps - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isDone ? AppColors.navyBase : AppColors.border,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final bool isDone;
  final bool isCurrent;
  final String label;

  const _StepDot({
    required this.index,
    required this.isDone,
    required this.isCurrent,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    if (isDone) {
      bg = AppColors.navyBase;
      fg = Colors.white;
    } else if (isCurrent) {
      bg = AppColors.navyBright;
      fg = Colors.white;
    } else {
      bg = AppColors.surfaceAlt;
      fg = AppColors.textTertiary;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppColors.navyBase.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: isDone
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: fg,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isCurrent ? AppColors.navyBase : AppColors.textTertiary,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

/// 금액 입력 필드 (원화 포맷)
class CurrencyTextField extends StatefulWidget {
  final String label;
  final String hint;
  final int initialValue;
  final ValueChanged<int> onChanged;
  final String? helperText;

  const CurrencyTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.initialValue = 0,
    this.helperText,
  });

  @override
  State<CurrencyTextField> createState() => _CurrencyTextFieldState();
}

class _CurrencyTextFieldState extends State<CurrencyTextField> {
  late TextEditingController _controller;
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _controller = TextEditingController(
      text: widget.initialValue > 0 ? _formatComma(widget.initialValue) : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatComma(int value) {
    final s = value.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write(',');
      result.write(s[i]);
    }
    return result.toString();
  }

  int _parse(String text) {
    return int.tryParse(text.replaceAll(',', '')) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            suffixText: '원',
          ),
          onChanged: (text) {
            final value = _parse(text);
            widget.onChanged(value);
            setState(() => _value = value);
            // 포맷 업데이트 (커서 끝으로)
            final formatted = _formatComma(value);
            if (formatted != text && text.isNotEmpty) {
              _controller.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
          },
        ),
        if (_value > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.navyBase.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '= ${formatKoreanCurrency(_value)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyBase,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        if (widget.helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              widget.helperText!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }
}

/// 정수 금액(원)을 한국식 억/만 단위 문자열로 변환.
///
/// 예시:
/// - 0 → "0원"
/// - 50_000 → "5만원"
/// - 530_000_000 → "5억 3,000만원"
/// - 1_532_873_000 → "15억 3,287만 3,000원"
String formatKoreanCurrency(int value) {
  if (value == 0) return '0원';
  final negative = value < 0;
  int abs = value.abs();

  String fmt(int n) {
    final s = n.toString();
    final out = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }

  final eok = abs ~/ 100000000;
  abs %= 100000000;
  final man = abs ~/ 10000;
  final won = abs % 10000;

  final parts = <String>[];
  if (eok > 0) parts.add('${fmt(eok)}억');
  if (man > 0) parts.add('${fmt(man)}만');
  if (won > 0) parts.add(fmt(won));

  final body = parts.isEmpty ? '0' : parts.join(' ');
  return '${negative ? '-' : ''}$body원';
}

/// 태그 배지
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// 하단 고정 CTA 버튼 영역
class BottomCta extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool isLoading;

  const BottomCta({
    super.key,
    required this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 12, 20, MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (secondaryLabel != null) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel!),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: secondaryLabel != null ? 2 : 1,
            child: ElevatedButton(
              onPressed: isLoading ? null : onPrimary,
              child: isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(primaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}
