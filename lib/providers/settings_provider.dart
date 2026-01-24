import 'package:flutter/foundation.dart';
import '../services/settings_service.dart';

class SettingsProvider with ChangeNotifier {
  String _signatureName = '';
  String _signatureTitle = '';
  String _signatureCompany = '';
  String _signatureNotes = '';
  String _defaultCurrencyCode = 'EUR';

  String get signatureName => _signatureName;
  String get signatureTitle => _signatureTitle;
  String get signatureCompany => _signatureCompany;
  String get signatureNotes => _signatureNotes;
  String get defaultCurrencyCode => _defaultCurrencyCode;

  SettingsProvider() {
    _load();
  }

  void _load() {
    _signatureName = SettingsService.getSignatureName();
    _signatureTitle = SettingsService.getSignatureTitle();
    _signatureCompany = SettingsService.getSignatureCompany();
    _signatureNotes = SettingsService.getSignatureNotes();
    _defaultCurrencyCode = SettingsService.getDefaultCurrencyCode();
    notifyListeners();
  }

  Future<void> updateSignature({
    required String name,
    required String title,
    required String company,
    required String notes,
  }) async {
    await SettingsService.saveSignatureInfo(
      name: name,
      title: title,
      company: company,
      notes: notes,
    );
    _signatureName = name;
    _signatureTitle = title;
    _signatureCompany = company;
    _signatureNotes = notes;
    notifyListeners();
  }

  Future<void> setDefaultCurrencyCode(String code) async {
    await SettingsService.setDefaultCurrencyCode(code);
    _defaultCurrencyCode = code;
    notifyListeners();
  }
}