import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/money_formatter.dart';
import '../domain/currency_models.dart';

export '../domain/currency_models.dart';

final fxRatesProvider = FutureProvider.autoDispose<CurrencyRateModel>((ref) async {
  return CurrencyRateModel(asOf: DateTime.now());
});

// ---------------------------------------------------------------------------
// Display Currency — Default IDR (Rupiah)
// ---------------------------------------------------------------------------

class DisplayCurrencyNotifier extends Notifier<String> {
  @override
  String build() {
    return 'IDR';
  }

  Future<bool> setCurrency(String currency) async {
    state = 'IDR';
    return true;
  }
}

final displayCurrencyProvider =
    NotifierProvider<DisplayCurrencyNotifier, String>(
  DisplayCurrencyNotifier.new,
);

// ---------------------------------------------------------------------------
// Formatter uang terpusat (selalu IDR)
// ---------------------------------------------------------------------------

final moneyFormatterProvider = Provider<String Function(num)>((ref) {
  return (amountIdr) => MoneyFormatter.format(amountIdr, currency: 'IDR');
});

extension CurrencyMoney on WidgetRef {
  String money(num amountIdr) {
    final formatter = watch(moneyFormatterProvider);
    return formatter(amountIdr);
  }
}

// ---------------------------------------------------------------------------
// Display Timezone — Default WIB (Asia/Jakarta)
// ---------------------------------------------------------------------------

final displayTimezoneProvider = StateProvider<String>((ref) => 'Asia/Jakarta');
