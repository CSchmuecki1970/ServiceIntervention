import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import '../providers/intervention_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../services/storage_service.dart';
import '../services/export_service.dart';
import 'package:file_picker/file_picker.dart';
import '../screens/view_archive_screen.dart';
import 'create_intervention_screen.dart';
import '../utils/currency_utils.dart';
import 'about_legal_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _signatureNameController = TextEditingController();
  final _signatureTitleController = TextEditingController();
  final _signatureCompanyController = TextEditingController();
  final _signatureNotesController = TextEditingController();
  bool _signatureLoaded = false;

  @override
  void dispose() {
    _signatureNameController.dispose();
    _signatureTitleController.dispose();
    _signatureCompanyController.dispose();
    _signatureNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          _buildSectionTitle(context, 'Appearance'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 12),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return DropdownButton<AppTheme>(
                        isExpanded: true,
                        value: themeProvider.currentTheme,
                        items: AppTheme.values.map((theme) {
                          return DropdownMenuItem(
                            value: theme,
                            child: Text(_getThemeName(theme)),
                          );
                        }).toList(),
                        onChanged: (theme) {
                          if (theme != null) {
                            themeProvider.setTheme(theme);
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Report Defaults Section
          _buildSectionTitle(context, 'Report Defaults'),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              if (!_signatureLoaded) {
                _signatureNameController.text = settingsProvider.signatureName;
                _signatureTitleController.text =
                    settingsProvider.signatureTitle;
                _signatureCompanyController.text =
                    settingsProvider.signatureCompany;
                _signatureNotesController.text =
                    settingsProvider.signatureNotes;
                _signatureLoaded = true;
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signature',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _signatureNameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _signatureTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Title / Role',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _signatureCompanyController,
                        decoration: const InputDecoration(
                          labelText: 'Company',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _signatureNotesController,
                        decoration: const InputDecoration(
                          labelText: 'Signature Notes (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Default Currency',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: settingsProvider.defaultCurrencyCode,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.currency_exchange),
                        ),
                        items: CurrencyUtils.supportedCurrencies
                            .map(
                              (currency) => DropdownMenuItem(
                                value: currency.code,
                                child: Text(currency.code),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            settingsProvider.setDefaultCurrencyCode(value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await settingsProvider.updateSignature(
                              name: _signatureNameController.text.trim(),
                              title: _signatureTitleController.text.trim(),
                              company: _signatureCompanyController.text.trim(),
                              notes: _signatureNotesController.text.trim(),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Report defaults saved'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Save Defaults'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Data Management Section
          _buildSectionTitle(context, 'Data Management'),
          Card(
            child: Column(
              children: [
                _buildTile(
                  context,
                  icon: Icons.download,
                  title: 'Export Data',
                  subtitle: 'Export all plannings to JSON file',
                  onTap: () => _showExportDialog(context),
                ),
                const Divider(height: 1),
                _buildTile(
                  context,
                  icon: Icons.upload,
                  title: 'Import Data',
                  subtitle: 'Import plannings from JSON file',
                  onTap: () => _showImportDialog(context),
                ),
                const Divider(height: 1),
                _buildTile(
                  context,
                  icon: Icons.archive,
                  title: 'View Archive',
                  subtitle: 'Open and preview a .zip archive',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ViewArchiveScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Backup Info Section
          _buildSectionTitle(context, 'Backup Information'),
          Consumer<InterventionProvider>(
            builder: (context, provider, child) {
              final backupInfo = provider.getBackupInfo();
              final interventionsCount = backupInfo['interventionsCount'] ?? 0;
              final customersCount = backupInfo['customersCount'] ?? 0;
              final lastSync = backupInfo['lastSync'] as String?;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        'Interventions',
                        '$interventionsCount',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Customers',
                        '$customersCount',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Last Sync',
                        lastSync != null
                            ? DateFormat('MMM dd, yyyy HH:mm')
                                .format(DateTime.parse(lastSync))
                            : 'Never',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // About & Legal Section
          _buildSectionTitle(context, 'Information'),
          Card(
            child: _buildTile(
              context,
              icon: Icons.info_outline,
              title: 'About & Legal',
              subtitle: 'View copyright, licenses, and terms',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AboutLegalScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Danger Zone
          _buildSectionTitle(context, 'Danger Zone', isRed: true),
          Card(
            child: _buildTile(
              context,
              icon: Icons.delete_forever,
              title: 'Clear All Data',
              subtitle: 'Delete all plannings and customers (cannot be undone)',
              onTap: () => _showDeleteConfirmation(context),
              isDestructive: true,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateInterventionScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Intervention'),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title,
      {bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isRed ? Colors.red : null,
            ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getThemeName(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'Light';
      case AppTheme.dark:
        return 'Dark';
      case AppTheme.blue:
        return 'Blue';
      case AppTheme.green:
        return 'Green';
      case AppTheme.purple:
        return 'Purple';
      case AppTheme.orange:
        return 'Orange';
      case AppTheme.pink:
        return 'Pink';
      case AppTheme.dracula:
        return 'Darkula';
    }
  }

  void _showExportDialog(BuildContext context) {
    try {
      final provider = context.read<InterventionProvider>();
      // Capture export data once to ensure consistency
      final jsonString = provider.exportData();
      final data = jsonDecode(jsonString);
      final interventionCount = (data['interventions'] as List?)?.length ?? 0;
      final customerCount = (data['customers'] as List?)?.length ?? 0;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Data'),
          content: Text(
              'Save your data to a JSON file in the Downloads folder?\n\n'
              'Interventions: $interventionCount\n'
              'Customers: $customerCount\n\n'
              'You can access this file through your device\'s file manager.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final timestamp =
                      DateTime.now().toIso8601String().replaceAll(':', '-');
                  final filename =
                      'service_intervention_export_$timestamp.json';
                  // Use the already-captured data to ensure consistency
                  final path =
                      await ExportService.exportJsonToFile(filename, data);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Exported to $path')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Export failed: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Save to File'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text('Select a JSON file to import your exported data.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['json'],
                  allowMultiple: false,
                );

                if (result == null || result.files.isEmpty) {
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No file selected')));
                  return;
                }

                final file = result.files.first;
                String text;

                if (file.bytes != null) {
                  text = String.fromCharCodes(file.bytes!);
                } else if (file.path != null) {
                  // For mobile platforms, we might need to read from path
                  final fileObj = File(file.path!);
                  text = await fileObj.readAsString();
                } else {
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unable to read file')));
                  return;
                }

                final provider = context.read<InterventionProvider>();

                // Parse import data first to show preview
                final importedData = jsonDecode(text) as Map<String, dynamic>;
                final interventionCount =
                    (importedData['interventions'] as List?)?.length ?? 0;
                final customerCount =
                    (importedData['customers'] as List?)?.length ?? 0;

                if (interventionCount == 0 && customerCount == 0) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Import file contains no data'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  return;
                }

                // Show confirmation with import summary
                if (mounted) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Import'),
                      content: Text('Ready to import:\n'
                          '• $interventionCount interventions\n'
                          '• $customerCount customers\n\n'
                          'This will merge with existing data.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Import'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;
                }

                await provider.importData(text);

                // Check how many interventions were actually imported
                final actualInterventions = provider.interventions.length;

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Import complete! $actualInterventions total interventions in database.',
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Import failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Choose File'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all plannings and customers. This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final provider = context.read<InterventionProvider>();
                await provider.clearAllData();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All data cleared'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Delete failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}
