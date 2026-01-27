import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:file_selector/file_selector.dart';

class ExportService {
  /// Gets the Downloads directory (public storage) where files are easily accessible
  static Future<String> _getDownloadsPath() async {
    if (Platform.isAndroid) {
      // On Android, use the public Downloads folder
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      return downloadDir.path;
    } else {
      // On other platforms, use the documents directory
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    }
  }

  /// Writes [content] into a file named [filename] in the Downloads directory
  /// (public storage on Android) and returns the absolute path to the created file.
  static Future<String> exportTextToFile(String filename, String content) async {
    final dir = await _getDownloadsPath();
    final file = File('$dir/$filename');
    await file.writeAsString(content);
    return file.path;
  }

  /// Writes binary [bytes] into a file named [filename] in the Downloads directory
  /// (public storage on Android) and returns the absolute path to the created file.
  static Future<String> exportBytesToFile(String filename, List<int> bytes) async {
    final dir = await _getDownloadsPath();
    final file = File('$dir/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Writes [data] as JSON into a file named [filename] in the Downloads directory
  /// (public storage on Android) and returns the absolute path to the created file.
  static Future<String> exportJsonToFile(String filename, Object data) async {
    final json = const JsonEncoder.withIndent('  ').convert(data);
    return exportTextToFile(filename, json);
  }

  /// Opens a file picker for a JSON file and returns the decoded JSON object,
  /// or throws if cancelled or invalid.
  static Future<dynamic> importJsonFromFile() async {
    const typeGroup = XTypeGroup(label: 'json', extensions: ['json']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) throw Exception('No file selected');
    final text = await file.readAsString();
    return jsonDecode(text);
  }
}
