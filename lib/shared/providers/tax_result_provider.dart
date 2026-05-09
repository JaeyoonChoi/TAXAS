import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/services/tax_calculator_service.dart';
import 'user_info_provider.dart';

part 'tax_result_provider.g.dart';

@riverpod
TaxResult taxResult(TaxResultRef ref) {
  final userInfo = ref.watch(userInfoProvider);
  return TaxCalculatorService.calculate(userInfo);
}
