import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:file_selector/file_selector.dart';

class ExportService {
  /// Writes [content] into a file named [filename] in the application's
  /// documents directory and returns the absolute path to the created file.
  static Future<String> exportTextToFile(String filename, String content) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    return file.path;
  }

  /// Writes binary [bytes] into a file named [filename] in the application's
  /// documents directory and returns the absolute path to the created file.
  static Future<String> exportBytesToFile(String filename, List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Writes [data] as JSON into a file named [filename] in the application's
  /// documents directory and returns the absolute path to the created file.
  static Future<String> exportJsonToFile(String filename, Object data) async {
    final json = const JsonEncoder.withIndent('  ').convert(data);
    return exportTextToFile(filename, json);
  }

  /// Opens a file picker for a JSON file and returns the decoded JSON object,
  /// or throws if cancelled or invalid.
  static Future<dynamic> importJsonFromFile() async {
    final typeGroup = XTypeGroup(label: 'json', extensions: ['json']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) throw Exception('No file selected');
    final text = await file.readAsString();
    return jsonDecode(text);
  }
}
