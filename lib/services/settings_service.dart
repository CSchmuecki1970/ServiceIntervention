import 'package:hive/hive.dart';

class SettingsService {
  static const String _settingsBox = 'settings_box';
  static late Box<dynamic> _box;

  static const String keySignatureName = 'signature_name';
  static const String keySignatureTitle = 'signature_title';
  static const String keySignatureCompany = 'signature_company';
  static const String keySignatureNotes = 'signature_notes';
  static const String keyDefaultCurrency = 'default_currency';

  static Future<void> init() async {
    _box = await Hive.openBox<dynamic>(_settingsBox);
  }

  static String getSignatureName() => _box.get(keySignatureName, defaultValue: '') as String;
  static String getSignatureTitle() => _box.get(keySignatureTitle, defaultValue: '') as String;
  static String getSignatureCompany() => _box.get(keySignatureCompany, defaultValue: '') as String;
  static String getSignatureNotes() => _box.get(keySignatureNotes, defaultValue: '') as String;

  static Map<String, String> getSignatureInfo() {
    return {
      'name': getSignatureName(),
      'title': getSignatureTitle(),
      'company': getSignatureCompany(),
      'notes': getSignatureNotes(),
    };
  }

  static Future<void> saveSignatureInfo({
    required String name,
    required String title,
    required String company,
    required String notes,
  }) async {
    await _box.put(keySignatureName, name);
    await _box.put(keySignatureTitle, title);
    await _box.put(keySignatureCompany, company);
    await _box.put(keySignatureNotes, notes);
  }

  static String getDefaultCurrencyCode() =>
      _box.get(keyDefaultCurrency, defaultValue: 'EUR') as String;

  static Future<void> setDefaultCurrencyCode(String code) async {
    await _box.put(keyDefaultCurrency, code);
  }
}