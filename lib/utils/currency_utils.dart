class CurrencyOption {
  final String code;
  final String name;
  final String symbol;

  const CurrencyOption({
    required this.code,
    required this.name,
    required this.symbol,
  });
}

class CurrencyUtils {
  static const List<CurrencyOption> supportedCurrencies = [
    CurrencyOption(code: 'EUR', name: 'Euro', symbol: '€'),
    CurrencyOption(code: 'GBP', name: 'British Pound', symbol: '£'),
    CurrencyOption(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF'),
    CurrencyOption(code: 'SEK', name: 'Swedish Krona', symbol: 'SEK'),
    CurrencyOption(code: 'NOK', name: 'Norwegian Krone', symbol: 'NOK'),
    CurrencyOption(code: 'DKK', name: 'Danish Krone', symbol: 'DKK'),
    CurrencyOption(code: 'PLN', name: 'Polish Zloty', symbol: 'PLN'),
    CurrencyOption(code: 'CZK', name: 'Czech Koruna', symbol: 'CZK'),
    CurrencyOption(code: 'HUF', name: 'Hungarian Forint', symbol: 'HUF'),
    CurrencyOption(code: 'RON', name: 'Romanian Leu', symbol: 'RON'),
    CurrencyOption(code: 'BGN', name: 'Bulgarian Lev', symbol: 'BGN'),
    CurrencyOption(code: 'HRK', name: 'Croatian Kuna', symbol: 'HRK'),
    CurrencyOption(code: 'ISK', name: 'Icelandic Krona', symbol: 'ISK'),
    CurrencyOption(code: 'USD', name: 'US Dollar', symbol: r'$'),
  ];

  static String symbolFor(String code) {
    return supportedCurrencies
            .firstWhere(
              (currency) => currency.code == code,
              orElse: () => supportedCurrencies.first,
            )
            .symbol;
  }

  static String labelFor(String code) {
    final currency = supportedCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => supportedCurrencies.first,
    );
    return '${currency.name} (${currency.code}) — ${currency.symbol}';
  }
}
