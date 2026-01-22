import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/intervention_provider.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Backup Info Section
          _buildSectionTitle(context, 'Backup Information'),
          Consumer<InterventionProvider>(
            builder: (context, provider, child) {
              final backupInfo = provider.getBackupInfo();
              final interventionsCount =
                  backupInfo['interventionsCount'] ?? 0;
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
        return 'Dracula';
    }
  }

  void _showExportDialog(BuildContext context) {
    try {
      final provider = context.read<InterventionProvider>();
      final jsonData = provider.exportData();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your data has been exported. Copy it below to save:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    jsonData,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data copied to clipboard'),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Copy to Clipboard'),
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
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Paste your exported JSON data below:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              minLines: 6,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: 'Paste JSON data here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
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
                await provider.importData(controller.text);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data imported successfully!'),
                      backgroundColor: Colors.green,
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
            child: const Text('Import'),
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
