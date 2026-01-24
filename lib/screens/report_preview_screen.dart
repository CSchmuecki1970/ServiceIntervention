import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/service_intervention.dart';
import '../services/report_service.dart';

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
