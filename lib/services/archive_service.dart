import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/service_intervention.dart';
import 'report_service.dart';

class ArchiveService {
  /// Creates a zip archive for the given [intervention]. The archive will
  /// include `intervention.json`, the generated PDF report (if requested),
  /// and all files located in `intervention.documents`.
  /// Returns the absolute path to the created zip file.
  static Future<String> createInterventionArchive(
    ServiceIntervention intervention, {
    bool includePdfReport = true,
  }) async {
    final archive = Archive();

    // Add intervention JSON
    final jsonContent = intervention.toJson();
    final jsonBytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(jsonContent));
    archive.addFile(ArchiveFile('intervention.json', jsonBytes.length, jsonBytes));

    // Optionally add PDF report
    if (includePdfReport) {
      try {
        final pdfBytes = await ReportService.buildReportPdfBytes(intervention);
        archive.addFile(ArchiveFile('report.pdf', pdfBytes.length, pdfBytes));
      } catch (_) {
        // ignore PDF generation errors — archive will still contain JSON and attachments
      }
    }

    // Add attachments
    for (final docPath in intervention.documents) {
      try {
        final file = File(docPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final filename = p.basename(docPath);
          archive.addFile(ArchiveFile(p.join('attachments', filename), bytes.length, bytes));
        }
      } catch (_) {
        // continue on errors
      }
    }

    // Encode archive
    final encoder = ZipEncoder();
    final data = encoder.encode(archive)!;

    // Save to documents
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = 'Intervention_${intervention.id}_$timestamp.zip';
    final outFile = File(p.join(dir.path, fileName));
    await outFile.writeAsBytes(data, flush: true);
    return outFile.path;
  }

  /// Reads an archive file and returns a list of [ArchiveFile] entries.
  static Future<Archive> readArchiveFile(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    return archive;
  }
}
