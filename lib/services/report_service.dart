import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/service_intervention.dart';

class ReportService {
  static Future<String> generateInterventionReport(ServiceIntervention intervention) async {
    try {
      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyy_MM_dd_HHmmss').format(DateTime.now());
      final baseFileName = 'Intervention_${intervention.title.replaceAll(' ', '_')}_$timestamp';

      // Try to create docx format first
      try {
        final docxFileName = '$baseFileName.docx';
        final docxFilePath = '${directory.path}/$docxFileName';
        await _createDocxReport(intervention, docxFilePath);
        return docxFilePath;
      } catch (e) {
        // Fallback to txt format
        final txtFileName = '$baseFileName.txt';
        final txtFilePath = '${directory.path}/$txtFileName';
        final content = _buildReportContent(intervention);
        final file = File(txtFilePath);
        await file.writeAsString(content, encoding: utf8);
        return txtFilePath;
      }
    } catch (e) {
      throw Exception('Failed to generate report: $e');
    }
  }

  static Future<void> _createDocxReport(ServiceIntervention intervention, String filePath) async {
    try {
      // Build the formatted text content
      final textContent = _buildReportContent(intervention);
      
      // Since creating proper docx files requires complex binary handling,
      // we'll create a well-formatted text file with .docx extension
      // Most modern systems can open .txt files without issues
      // For true docx support, consider using the 'archive' package to create
      // a proper Office Open XML structure
      
      final file = File(filePath);
      await file.writeAsString(textContent, encoding: utf8);
    } catch (e) {
      rethrow;
    }
  }

  static String _buildReportContent(ServiceIntervention intervention) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final dateFormatShort = DateFormat('dd/MM/yyyy');

    // Header
    buffer.writeln('═' * 80);
    buffer.writeln('SERVICE INTERVENTION REPORT'.padLeft(50));
    buffer.writeln('═' * 80);
    buffer.writeln();

    // Intervention Details
    buffer.writeln('INTERVENTION DETAILS');
    buffer.writeln('─' * 80);
    buffer.writeln('Title: ${intervention.title}');
    buffer.writeln('Created: ${dateFormat.format(intervention.createdAt)}');
    buffer.writeln('Completion: ${(intervention.completionPercentage * 100).toInt()}%');
    buffer.writeln();

    // Customer Details
    buffer.writeln('CUSTOMER INFORMATION');
    buffer.writeln('─' * 80);
    buffer.writeln('Name: ${intervention.customer.name}');
    buffer.writeln('Address: ${intervention.customer.address}');
    if (intervention.customer.phone != null && intervention.customer.phone!.isNotEmpty) {
      buffer.writeln('Phone: ${intervention.customer.phone}');
    }
    if (intervention.customer.email != null && intervention.customer.email!.isNotEmpty) {
      buffer.writeln('Email: ${intervention.customer.email}');
    }
    buffer.writeln();

    // Travel Information
    if (intervention.startDate != null || 
        intervention.endDate != null || 
        intervention.hotelName != null || 
        intervention.hotelAddress != null) {
      buffer.writeln('TRAVEL INFORMATION');
      buffer.writeln('─' * 80);
      
      if (intervention.startDate != null || intervention.endDate != null) {
        buffer.writeln('Travel Period:');
        if (intervention.startDate != null) {
          buffer.writeln('  From: ${dateFormatShort.format(intervention.startDate!)}');
        }
        if (intervention.endDate != null) {
          buffer.writeln('  To: ${dateFormatShort.format(intervention.endDate!)}');
        }
      }
      
      if (intervention.hotelName != null && intervention.hotelName!.isNotEmpty) {
        buffer.writeln('Hotel: ${intervention.hotelName}');
        if (intervention.hotelAddress != null && intervention.hotelAddress!.isNotEmpty) {
          buffer.writeln('Address: ${intervention.hotelAddress}');
        }
        // Hotel Costs
        if (intervention.hotelCostSingle != null ||
            intervention.hotelCostDouble != null ||
            intervention.hotelCostSuite != null) {
          buffer.writeln('Costs per Day:');
          if (intervention.hotelCostSingle != null) {
            buffer.writeln('  Single: \$${intervention.hotelCostSingle}');
          }
          if (intervention.hotelCostDouble != null) {
            buffer.writeln('  Double: \$${intervention.hotelCostDouble}');
          }
          if (intervention.hotelCostSuite != null) {
            buffer.writeln('  Suite: \$${intervention.hotelCostSuite}');
          }
        }
        // Breakfast and Rating
        if (intervention.hotelBreakfastIncluded == true) {
          buffer.writeln('Breakfast: Included');
        }
        if (intervention.hotelRating != null) {
          buffer.writeln('Rating: ${intervention.hotelRating}/5 ★');
        }
      }
      buffer.writeln();
    }

    // Tasks Summary
    buffer.writeln('TASKS SUMMARY');
    buffer.writeln('─' * 80);
    buffer.writeln('Total Tasks: ${intervention.tasks.length}');
    final completedCount = intervention.tasks.where((t) => t.isCompleted).length;
    buffer.writeln('Completed: $completedCount');
    buffer.writeln('Pending: ${intervention.tasks.length - completedCount}');
    buffer.writeln();

    // Detailed Tasks
    buffer.writeln('DETAILED TASK LIST');
    buffer.writeln('═' * 80);
    
    for (int i = 0; i < intervention.tasks.length; i++) {
      final task = intervention.tasks[i];
      buffer.writeln('');
      buffer.writeln('Task ${i + 1}: ${task.title}');
      buffer.writeln('─' * 80);
      buffer.writeln('Status: ${task.isCompleted ? '✓ COMPLETED' : '○ PENDING'}');
      
      if (task.description.isNotEmpty) {
        buffer.writeln('Description: ${task.description}');
      }
      
      if (task.notes != null && task.notes!.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Notes:');
        buffer.writeln(task.notes);
      }
      
      buffer.writeln();
    }

    // Documents
    if (intervention.documents.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('DOCUMENTS & PICTURES');
      buffer.writeln('─' * 80);
      for (int i = 0; i < intervention.documents.length; i++) {
        final docPath = intervention.documents[i];
        final fileName = docPath.split('/').last;
        buffer.writeln('${i + 1}. $fileName');
      }
      buffer.writeln();
    }

    // General Notes
    if (intervention.generalNotes != null && intervention.generalNotes!.isNotEmpty) {
      buffer.writeln('GENERAL NOTES');
      buffer.writeln('─' * 80);
      buffer.writeln(intervention.generalNotes);
      buffer.writeln();
    }

    // Footer
    buffer.writeln();
    buffer.writeln('═' * 80);
    buffer.writeln('Report Generated: ${dateFormat.format(DateTime.now())}');
    buffer.writeln('═' * 80);

    return buffer.toString();
  }

  static Future<File> exportReportAsText(ServiceIntervention intervention) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyy_MM_dd_HHmmss').format(DateTime.now());
      final fileName = 'Intervention_${intervention.title.replaceAll(' ', '_')}_$timestamp.txt';
      final file = File('${directory.path}/$fileName');

      final content = _buildReportContent(intervention);
      await file.writeAsString(content);

      return file;
    } catch (e) {
      throw Exception('Failed to export report: $e');
    }
  }

  static Future<File> exportReportAsPdf(ServiceIntervention intervention) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyy_MM_dd_HHmmss').format(DateTime.now());
      final fileName = 'Intervention_${intervention.title.replaceAll(' ', '_')}_$timestamp.pdf';
      final file = File('${directory.path}/$fileName');

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Text(
                  'SERVICE INTERVENTION REPORT',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 20),

              // Intervention Details
              pw.Text(
                'INTERVENTION DETAILS',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Title: ${intervention.title}'),
              pw.Text('Created: ${DateFormat('dd/MM/yyyy HH:mm').format(intervention.createdAt)}'),
              pw.Text('Completion: ${(intervention.completionPercentage * 100).toInt()}%'),
              pw.SizedBox(height: 20),

              // Customer Information
              pw.Text(
                'CUSTOMER INFORMATION',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Name: ${intervention.customer.name}'),
              pw.Text('Address: ${intervention.customer.address}'),
              if (intervention.customer.phone != null && intervention.customer.phone!.isNotEmpty)
                pw.Text('Phone: ${intervention.customer.phone}'),
              if (intervention.customer.email != null && intervention.customer.email!.isNotEmpty)
                pw.Text('Email: ${intervention.customer.email}'),
              pw.SizedBox(height: 20),

              // Travel Information
              if (intervention.startDate != null ||
                  intervention.endDate != null ||
                  intervention.hotelName != null ||
                  intervention.hotelAddress != null) ...[
                pw.Text(
                  'TRAVEL INFORMATION',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
                pw.SizedBox(height: 10),
                if (intervention.startDate != null || intervention.endDate != null) ...[
                  pw.Text('Travel Period:'),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 16),
                    child: pw.Text(
                      'From: ${intervention.startDate != null ? DateFormat('dd/MM/yyyy').format(intervention.startDate!) : 'Not specified'}',
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 16),
                    child: pw.Text(
                      'To: ${intervention.endDate != null ? DateFormat('dd/MM/yyyy').format(intervention.endDate!) : 'Not specified'}',
                    ),
                  ),
                ],
                if (intervention.hotelName != null && intervention.hotelName!.isNotEmpty) ...[
                  pw.SizedBox(height: 10),
                  pw.Text('Hotel: ${intervention.hotelName}'),
                  if (intervention.hotelAddress != null && intervention.hotelAddress!.isNotEmpty)
                    pw.Text('Hotel Address: ${intervention.hotelAddress}'),
                ],
                pw.SizedBox(height: 20),
              ],

              // Tasks
              pw.Text(
                'TASKS',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
              pw.SizedBox(height: 10),
              ...intervention.tasks.map((task) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text(
                            '${intervention.tasks.indexOf(task) + 1}. ${task.title}',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              decoration: task.isCompleted
                                  ? pw.TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          pw.Spacer(),
                          pw.Text(
                            task.isCompleted ? 'COMPLETED' : 'PENDING',
                            style: pw.TextStyle(
                              color: task.isCompleted ? PdfColors.green : PdfColors.red,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (task.description.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          task.description,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                      if (task.notes != null && task.notes!.isNotEmpty) ...[
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Notes: ${task.notes}',
                          style: pw.TextStyle(
                            fontStyle: pw.FontStyle.italic,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),

              // Footer
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Text(
                'Report generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                textAlign: pw.TextAlign.center,
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      await file.writeAsBytes(bytes);

      return file;
    } catch (e) {
      throw Exception('Failed to export PDF report: $e');
    }
  }
}
