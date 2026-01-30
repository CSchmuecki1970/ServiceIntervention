import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:archive/archive.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class ViewArchiveScreen extends StatefulWidget {
  const ViewArchiveScreen({super.key});

  @override
  State<ViewArchiveScreen> createState() => _ViewArchiveScreenState();
}

class _ViewArchiveScreenState extends State<ViewArchiveScreen> {
  Archive? _archive;
  String? _archivePath;

  Future<void> _pickArchive() async {
    try {
      final result = await openFile(acceptedTypeGroups: [const XTypeGroup(label: 'zip', extensions: ['zip'])]);
      if (result == null) return;
      final bytes = await result.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      setState(() {
        _archive = archive;
        _archivePath = result.path;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open archive: $e')));
      }
    }
  }

  void _previewEntry(ArchiveFile entry) async {
    final name = entry.name.toLowerCase();
    final data = entry.content as List<int>;

    if (name.endsWith('.png') || name.endsWith('.jpg') || name.endsWith('.jpeg')) {
      // show image
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: InteractiveViewer(
            child: Image.memory(Uint8List.fromList(data)),
          ),
        ),
      );
      return;
    }

    if (name.endsWith('.txt') || name.endsWith('.json') || name.endsWith('.md') || name.endsWith('.csv')) {
      final text = String.fromCharCodes(data);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(entry.name),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(text),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
      return;
    }

    if (name.endsWith('.pdf')) {
      final bytes = Uint8List.fromList(data);
      // Use printing's PdfPreview to show the bytes
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return Scaffold(
          appBar: AppBar(title: Text(entry.name)),
          body: PdfPreview(
            build: (format) async => bytes,
          ),
        );
      }));
      return;
    }

    // fallback
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.name),
        content: const Text('No preview available for this file type.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<String> _writeEntryToTemp(ArchiveFile entry) async {
    final dir = await getTemporaryDirectory();
    final filename = p.basename(entry.name);
    final outPath = p.join(dir.path, filename);
    final outFile = File(outPath);
    await outFile.writeAsBytes(entry.content as List<int>);
    return outPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Archive'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Open Archive',
            onPressed: _pickArchive,
          ),
        ],
      ),
      body: _archive == null
          ? Center(
              child: ElevatedButton.icon(
                onPressed: _pickArchive,
                icon: const Icon(Icons.folder_open),
                label: const Text('Open Archive'),
              ),
            )
          : ListView.builder(
              itemCount: _archive!.length,
              itemBuilder: (context, index) {
                final entry = _archive![index];
                return ListTile(
                  title: Text(entry.name),
                  subtitle: Text('${entry.size} bytes'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_red_eye),
                        onPressed: () => _previewEntry(entry),
                      ),
                      IconButton(
                        icon: const Icon(Icons.file_download),
                        tooltip: 'Extract',
                        onPressed: () async {
                          // show progress
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Dialog(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(width: 16),
                                    Text('Extracting...'),
                                  ],
                                ),
                              ),
                            ),
                          );
                          try {
                            final outPath = await _writeEntryToTemp(entry);
                            if (mounted) Navigator.pop(context);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Extracted to $outPath'),
                                  action: SnackBarAction(
                                    label: 'Open',
                                    onPressed: () => OpenFile.open(outPath),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) Navigator.pop(context);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Extract failed: $e'), backgroundColor: Colors.red));
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        tooltip: 'Share',
                        onPressed: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Dialog(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(width: 16),
                                    Text('Preparing...'),
                                  ],
                                ),
                              ),
                            ),
                          );
                          try {
                            final outPath = await _writeEntryToTemp(entry);
                            if (mounted) Navigator.pop(context);
                            try {
                              await Share.shareXFiles([XFile(outPath)], text: entry.name);
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share failed: $e')));
                            }
                          } catch (e) {
                            if (mounted) Navigator.pop(context);
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Prepare failed: $e'), backgroundColor: Colors.red));
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
