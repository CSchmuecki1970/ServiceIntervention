import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/service_intervention.dart';
import '../services/report_service.dart';
import '../services/export_service.dart';

class ReportPreviewScreen extends StatelessWidget {
  final ServiceIntervention intervention;

  const ReportPreviewScreen({
    super.key,
    required this.intervention,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Preview'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close Preview',
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print Report',
            onPressed: () async {
              await Printing.layoutPdf(
                onLayout: (_) => ReportService.buildReportPdfBytes(intervention),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export PDF',
            onPressed: () async {
              final shouldExport = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Export Report'),
                  content: const Text('Save this report as a PDF to the device documents folder?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Export'),
                    ),
                  ],
                ),
              );

              if (shouldExport != true) return;

              try {
                final bytes = await ReportService.buildReportPdfBytes(intervention);
                final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
                final filename = 'Intervention_${intervention.title.replaceAll(' ', '_')}_$timestamp.pdf';
                final path = await ExportService.exportBytesToFile(filename, bytes);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved to $path')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) => ReportService.buildReportPdfBytes(intervention),
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }
}
