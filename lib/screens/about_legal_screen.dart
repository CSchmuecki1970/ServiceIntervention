import 'package:flutter/material.dart';

class AboutLegalScreen extends StatelessWidget {
  const AboutLegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About & Legal'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Information
          _buildSectionTitle(context, 'About Service Intervention'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Intervention Planner',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.1',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'A service intervention planning and guidance app for technicians',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Copyright
          _buildSectionTitle(context, 'Copyright'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '© 2026 Service Intervention',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All rights reserved. This software is provided as-is for personal and professional use.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Impressum (German Legal Imprint)
          _buildSectionTitle(context, 'Impressum'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verantwortlich für den Inhalt:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildImprint(context),
                  const SizedBox(height: 16),
                  Text(
                    'Diese Anwendung wird ohne kommerzielle Absicht bereitgestellt.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Third-party Licenses
          _buildSectionTitle(context, 'Open Source Licenses'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This application uses the following open source packages:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 16),
                  ..._buildDependencies(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // License Text
          _buildSectionTitle(context, 'License'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Text(
                  _getLicenseText(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildImprint(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Carsten Schmücker',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Selbecker Str. 267',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          '58091 Hagen',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'Tel: 0049/17675898102',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  List<Widget> _buildDependencies() {
    final dependencies = [
      ('flutter', 'Google Flutter Framework'),
      ('provider', 'State management library'),
      ('hive', 'Lightweight database'),
      ('hive_flutter', 'Hive integration for Flutter'),
      ('intl', 'Internationalization and localization'),
      ('uuid', 'UUID generation'),
      ('path_provider', 'File system paths'),
      ('speech_to_text', 'Speech recognition'),
      ('docx_template', 'Word document templating'),
      ('file_selector', 'File selection'),
      ('pdf', 'PDF generation'),
      ('printing', 'Document printing'),
      ('archive', 'Archive handling'),
      ('open_file', 'Open files'),
      ('share_plus', 'Share functionality'),
      ('file_picker', 'File picker'),
      ('cupertino_icons', 'iOS-style icons'),
    ];

    return dependencies
        .map(
          (dep) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dep.$1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  dep.$2,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  String _getLicenseText() {
    return '''SERVICE INTERVENTION PLANNER
License & Terms of Use

1. PERSONAL USE LICENSE
This software is provided for personal and professional use. You are granted a non-exclusive, non-transferable license to use this software.

2. RESTRICTIONS
You may not:
- Distribute, sublicense, or sell this software
- Reverse engineer or decompile this software
- Remove or alter any proprietary notices
- Use this software in a commercial product without permission

3. WARRANTY DISCLAIMER
This software is provided "AS IS" without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and non-infringement.

4. LIABILITY LIMITATION
In no event shall the author be liable for any special, indirect, incidental, consequential or punitive damages, even if advised of the possibility of such damages.

5. DATA PRIVACY
This software stores data locally on your device. No data is transmitted to remote servers without your explicit action (export/import).

6. THIRD-PARTY COMPONENTS
This software includes third-party open source components. See the Open Source Licenses section above for details.

7. CHANGES TO TERMS
These terms may be updated at any time. Continued use of the software indicates acceptance of updated terms.

8. GOVERNING LAW
These terms are governed by applicable law and jurisdiction where appropriate.

Last Updated: February 2026''';
  }
}
